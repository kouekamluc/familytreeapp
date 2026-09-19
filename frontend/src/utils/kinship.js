/**
 * Kinship Calculation & Relationship Finder Utility
 * Computes exact biological, spousal, and ancestral relationships
 * between any two family members across generations.
 */

export function calculateKinship(personAId, personBId, people = [], relationships = []) {
  if (!personAId || !personBId) return null
  const aId = parseInt(personAId)
  const bId = parseInt(personBId)

  const peopleMap = new Map(people.map(p => [p.id, p]))
  const personA = peopleMap.get(aId)
  const personB = peopleMap.get(bId)

  if (!personA || !personB) return null
  if (aId === bId) {
    return {
      title: 'Same Person',
      relationship: 'Self',
      description: `${personA.first_name || personA.firstName} is viewing their own profile.`,
      culturalHonorific: 'Le Pilier',
      generationDifference: 0,
      path: [personA]
    }
  }

  // Maps
  const parentMap = new Map() // childId -> [parentId]
  const childrenMap = new Map() // parentId -> [childId]
  const spouseMap = new Map() // personId -> [spouseId]
  const graph = new Map() // undirected graph for pathfinding: id -> [{ targetId, type }]

  relationships.forEach(r => {
    const p1 = parseInt(r.person1_id || r.person1 || r.source)
    const p2 = parseInt(r.person2_id || r.person2 || r.target)
    const type = (r.relationship_type || r.type || 'PARENT').toUpperCase()

    if (!graph.has(p1)) graph.set(p1, [])
    if (!graph.has(p2)) graph.set(p2, [])

    if (type === 'PARENT') {
      if (!parentMap.has(p2)) parentMap.set(p2, [])
      parentMap.get(p2).push(p1)

      if (!childrenMap.has(p1)) childrenMap.set(p1, [])
      childrenMap.get(p1).push(p2)

      graph.get(p1).push({ targetId: p2, type: 'child' })
      graph.get(p2).push({ targetId: p1, type: 'parent' })
    } else if (type === 'SPOUSE') {
      if (!spouseMap.has(p1)) spouseMap.set(p1, [])
      if (!spouseMap.has(p2)) spouseMap.set(p2, [])
      spouseMap.get(p1).push(p2)
      spouseMap.get(p2).push(p1)

      graph.get(p1).push({ targetId: p2, type: 'spouse' })
      graph.get(p2).push({ targetId: p1, type: 'spouse' })
    }
  })

  const aGender = personA.gender === 'F' || personA.gender === 'Female' ? 'F' : 'M'
  const bGender = personB.gender === 'F' || personB.gender === 'Female' ? 'F' : 'M'

  const aName = `${personA.first_name || personA.firstName} ${personA.last_name || personA.lastName}`.trim()
  const bName = `${personB.first_name || personB.firstName} ${personB.last_name || personB.lastName}`.trim()

  // 1. Spouses
  const spousesOfA = spouseMap.get(aId) || []
  if (spousesOfA.includes(bId)) {
    return {
      title: 'Spousal Union',
      relationship: bGender === 'F' ? 'Wife' : 'Husband',
      summary: `${bName} is the spouse of ${aName}`,
      description: 'Connected in holy matrimony and lineage partnership.',
      culturalHonorific: 'Alliance Sacrée & Rameau Familial',
      generationDifference: 0,
      path: [personA, personB]
    }
  }

  // 2. Direct Parent / Child
  const parentsOfA = parentMap.get(aId) || []
  if (parentsOfA.includes(bId)) {
    return {
      title: bGender === 'M' ? 'Father' : 'Mother',
      relationship: bGender === 'M' ? 'Father (Papa)' : 'Mother (Mama)',
      summary: `${bName} is the ${bGender === 'M' ? 'father' : 'mother'} of ${aName}`,
      description: `Direct biological elder (1 generation above).`,
      culturalHonorific: bGender === 'M' ? 'Papa / Pilier de la Lignée' : 'Maman / Source Sacrée',
      generationDifference: 1,
      path: [personA, personB]
    }
  }

  const childrenOfA = childrenMap.get(aId) || []
  if (childrenOfA.includes(bId)) {
    return {
      title: bGender === 'M' ? 'Son' : 'Daughter',
      relationship: bGender === 'M' ? 'Son' : 'Daughter',
      summary: `${bName} is the ${bGender === 'M' ? 'son' : 'daughter'} of ${aName}`,
      description: `Direct biological descendant (1 generation below).`,
      culturalHonorific: 'Enfant de la Dynastie',
      generationDifference: -1,
      path: [personA, personB]
    }
  }

  // 3. Siblings (Full or Half)
  const parentsOfB = parentMap.get(bId) || []
  const sharedParents = parentsOfA.filter(pId => parentsOfB.includes(pId))
  if (sharedParents.length > 0) {
    const isFull = sharedParents.length >= 2
    return {
      title: bGender === 'F' ? 'Sister' : 'Brother',
      relationship: bGender === 'F' ? 'Sister (Sœur)' : 'Brother (Frère)',
      summary: `${bName} and ${aName} are ${bGender === 'F' ? 'sisters' : 'brothers'} sharing parents`,
      description: `${isFull ? 'Full' : 'Half'} siblings sharing the royal bloodline of ${sharedParents.map(id => peopleMap.get(id)?.first_name || 'Elder').join(' & ')}.`,
      culturalHonorific: 'Frère / Sœur de Sang (Même Arbre)',
      generationDifference: 0,
      path: [personA, peopleMap.get(sharedParents[0]), personB].filter(Boolean)
    }
  }

  // 4. Grandparent / Grandchild (2 generations)
  // Check if B is grandparent of A
  for (const parentId of parentsOfA) {
    const grandParents = parentMap.get(parentId) || []
    if (grandParents.includes(bId)) {
      const parent = peopleMap.get(parentId)
      const parentIsFather = parent?.gender !== 'F' && parent?.gender !== 'Female'
      const side = parentIsFather ? 'Paternal' : 'Maternal'
      const title = bGender === 'M' ? `${side} Grandfather` : `${side} Grandmother`
      return {
        title,
        relationship: title,
        summary: `${bName} is the ${title} of ${aName}`,
        description: `Grandparent 2 generations above through ${parent?.first_name || 'parent'}.`,
        culturalHonorific: bGender === 'M' ? 'Grand-Père / Patriarche Ancien' : 'Grand-Mère / Reine-Mère',
        generationDifference: 2,
        path: [personA, parent, personB].filter(Boolean)
      }
    }
  }

  // Check if A is grandparent of B
  for (const parentId of parentsOfB) {
    const grandParents = parentMap.get(parentId) || []
    if (grandParents.includes(aId)) {
      const parent = peopleMap.get(parentId)
      const title = bGender === 'M' ? 'Grandson' : 'Granddaughter'
      return {
        title,
        relationship: title,
        summary: `${bName} is the ${title} of ${aName}`,
        description: `Grandchild 2 generations below through ${parent?.first_name || 'child'}.`,
        culturalHonorific: 'Petit-Fils / Petite-Fille de la Lignée',
        generationDifference: -2,
        path: [personA, parent, personB].filter(Boolean)
      }
    }
  }

  // 5. Great-Grandparent / Great-Grandchild (3 generations)
  for (const parentId of parentsOfA) {
    const grandParents = parentMap.get(parentId) || []
    for (const gpId of grandParents) {
      const greatGPs = parentMap.get(gpId) || []
      if (greatGPs.includes(bId)) {
        const title = bGender === 'M' ? 'Great-Grandfather' : 'Great-Grandmother'
        return {
          title,
          relationship: title,
          summary: `${bName} is the ${title} of ${aName}`,
          description: `Venerated ancestral root 3 generations above.`,
          culturalHonorific: 'Arrière-Grand-Parent / Ancêtre Vénéré',
          generationDifference: 3,
          path: [personA, peopleMap.get(parentId), peopleMap.get(gpId), personB].filter(Boolean)
        }
      }
    }
  }

  for (const parentId of parentsOfB) {
    const grandParents = parentMap.get(parentId) || []
    for (const gpId of grandParents) {
      const greatGPs = parentMap.get(gpId) || []
      if (greatGPs.includes(aId)) {
        const title = bGender === 'M' ? 'Great-Grandson' : 'Great-Granddaughter'
        return {
          title,
          relationship: title,
          summary: `${bName} is the ${title} of ${aName}`,
          description: `Descendant 3 generations below.`,
          culturalHonorific: 'Arrière-Petit-Enfant de la Lignée',
          generationDifference: -3,
          path: [personA, peopleMap.get(gpId), peopleMap.get(parentId), personB].filter(Boolean)
        }
      }
    }
  }

  // 6. Aunt / Uncle & Niece / Nephew
  // Check if B is sibling of A's parent (Aunt / Uncle)
  for (const parentId of parentsOfA) {
    const parentsOfMyParent = parentMap.get(parentId) || []
    const auntsUncles = parentsOfB.filter(pId => parentsOfMyParent.includes(pId))
    if (auntsUncles.length > 0 && bId !== parentId) {
      const parent = peopleMap.get(parentId)
      const parentIsFather = parent?.gender !== 'F' && parent?.gender !== 'Female'
      const side = parentIsFather ? 'Paternal' : 'Maternal'
      const title = bGender === 'M' ? `${side} Uncle` : `${side} Aunt`
      return {
        title,
        relationship: title,
        summary: `${bName} is the ${title} of ${aName}`,
        description: `Sibling of ${aName}'s ${parentIsFather ? 'father' : 'mother'} (${parent?.first_name || ''}).`,
        culturalHonorific: bGender === 'M' ? 'Oncle / Frère de mon Père' : 'Tante / Sœur de la Maison',
        generationDifference: 1,
        path: [personA, parent, personB].filter(Boolean)
      }
    }
  }

  // Check if A is sibling of B's parent (B is Niece / Nephew)
  for (const parentId of parentsOfB) {
    const parentsOfBParent = parentMap.get(parentId) || []
    const sharedWithA = parentsOfA.filter(pId => parentsOfBParent.includes(pId))
    if (sharedWithA.length > 0 && aId !== parentId) {
      const parent = peopleMap.get(parentId)
      const title = bGender === 'M' ? 'Nephew' : 'Niece'
      return {
        title,
        relationship: title,
        summary: `${bName} is the ${title} of ${aName}`,
        description: `Child of ${aName}'s sibling (${parent?.first_name || ''}).`,
        culturalHonorific: 'Neveu / Nièce du Rameau',
        generationDifference: -1,
        path: [personA, parent, personB].filter(Boolean)
      }
    }
  }

  // 7. First Cousins (Parents are siblings)
  for (const parentA of parentsOfA) {
    const gParentsA = parentMap.get(parentA) || []
    for (const parentB of parentsOfB) {
      const gParentsB = parentMap.get(parentB) || []
      const commonGPs = gParentsA.filter(gp => gParentsB.includes(gp))
      if (commonGPs.length > 0 && parentA !== parentB) {
        return {
          title: 'First Cousins',
          relationship: bGender === 'F' ? 'First Cousin (Cousine)' : 'First Cousin (Cousin)',
          summary: `${aName} and ${bName} are First Cousins`,
          description: `Share grandparents ${commonGPs.map(id => peopleMap.get(id)?.first_name || 'Grandparent').join(' & ')} through siblings ${peopleMap.get(parentA)?.first_name} and ${peopleMap.get(parentB)?.first_name}.`,
          culturalHonorific: 'Cousin(e) Germain(e) du Même Sang',
          generationDifference: 0,
          path: [personA, peopleMap.get(parentA), peopleMap.get(commonGPs[0]), peopleMap.get(parentB), personB].filter(Boolean)
        }
      }
    }
  }

  // 8. In-Laws
  // Is B spouse of a sibling of A?
  for (const siblingId of (childrenMap.get(parentsOfA[0]) || [])) {
    if (siblingId !== aId && (spouseMap.get(siblingId) || []).includes(bId)) {
      const title = bGender === 'M' ? 'Brother-in-law' : 'Sister-in-law'
      return {
        title,
        relationship: title,
        summary: `${bName} is the ${title} of ${aName}`,
        description: `Married to ${aName}'s sibling (${peopleMap.get(siblingId)?.first_name || ''}).`,
        culturalHonorific: 'Allié(e) par Mariage',
        generationDifference: 0,
        path: [personA, peopleMap.get(siblingId), personB].filter(Boolean)
      }
    }
  }

  // 9. General BFS Shortest Path
  const queue = [{ id: aId, path: [personA] }]
  const visited = new Set([aId])
  while (queue.length > 0) {
    const { id, path } = queue.shift()
    if (id === bId) {
      return {
        title: 'Extended Kin',
        relationship: 'Extended Kin',
        summary: `${aName} and ${bName} are connected via a ${path.length - 1}-step bloodline path`,
        description: `Connected along the royal lineage tree.`,
        culturalHonorific: 'Parent de la Grande Famille Royale',
        generationDifference: path.length,
        path
      }
    }

    const neighbors = graph.get(id) || []
    for (const n of neighbors) {
      if (!visited.has(n.targetId)) {
        visited.add(n.targetId)
        const nextPerson = peopleMap.get(n.targetId)
        if (nextPerson) {
          queue.push({ id: n.targetId, path: [...path, nextPerson] })
        }
      }
    }
  }

  return {
    title: 'Unlinked Branches',
    relationship: 'Unlinked',
    summary: `No direct kinship link recorded between ${aName} and ${bName} yet.`,
    description: 'Add a connecting parent, spouse, or child to unite their branches.',
    culturalHonorific: 'Membres du Même Royaume',
    generationDifference: 0,
    path: [personA, personB]
  }
}
