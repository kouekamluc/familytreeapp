from django.test import TestCase
from django.contrib.auth import get_user_model
from family.models import FamilyTree, Person, Relationship
from datetime import date

User = get_user_model()

class RelationshipDirectionTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='tester', password='password123')
        self.tree = FamilyTree.objects.create(name='Royal Family Tree', owner=self.user)

        # Create Grandparent, Parent, Spouse, Child, Sibling
        self.grandma = Person.objects.create(
            family_tree=self.tree,
            first_name='Amina',
            last_name='Henderson',
            gender='F',
            date_of_birth=date(1935, 1, 1)
        )
        self.father = Person.objects.create(
            family_tree=self.tree,
            first_name='Arthur',
            last_name='Henderson',
            gender='M',
            date_of_birth=date(1960, 4, 12)
        )
        self.mother = Person.objects.create(
            family_tree=self.tree,
            first_name='Eleanor',
            last_name='Henderson',
            gender='F',
            date_of_birth=date(1964, 8, 23)
        )
        self.son = Person.objects.create(
            family_tree=self.tree,
            first_name='Liam',
            last_name='Henderson',
            gender='M',
            date_of_birth=date(1992, 11, 5)
        )
        self.daughter = Person.objects.create(
            family_tree=self.tree,
            first_name='Grace',
            last_name='Henderson',
            gender='F',
            date_of_birth=date(1996, 7, 18)
        )

        # Golden rule: person1 = Parent, person2 = Child
        # 1. Grandma is parent of Father
        Relationship.objects.create(
            person1=self.grandma,
            person2=self.father,
            relationship_type='PARENT'
        )
        # 2. Father is parent of Son
        Relationship.objects.create(
            person1=self.father,
            person2=self.son,
            relationship_type='PARENT'
        )
        # 3. Father is parent of Daughter
        Relationship.objects.create(
            person1=self.father,
            person2=self.daughter,
            relationship_type='PARENT'
        )
        # 4. Mother is parent of Son
        Relationship.objects.create(
            person1=self.mother,
            person2=self.son,
            relationship_type='PARENT'
        )
        # 5. Mother is parent of Daughter
        Relationship.objects.create(
            person1=self.mother,
            person2=self.daughter,
            relationship_type='PARENT'
        )
        # 6. Father and Mother are Spouses
        Relationship.objects.create(
            person1=self.father,
            person2=self.mother,
            relationship_type='SPOUSE'
        )

    def test_parents_query(self):
        """Liam's parents must be Arthur and Eleanor, NOT his grandparents or descendants."""
        liam_parents = list(self.son.get_parents())
        self.assertEqual(len(liam_parents), 2)
        self.assertIn(self.father, liam_parents)
        self.assertIn(self.mother, liam_parents)

        arthur_parents = list(self.father.get_parents())
        self.assertEqual(len(arthur_parents), 1)
        self.assertIn(self.grandma, arthur_parents)

    def test_children_query(self):
        """Arthur's children must be Liam and Grace, NOT his mother Amina."""
        arthur_children = list(self.father.get_children())
        self.assertEqual(len(arthur_children), 2)
        self.assertIn(self.son, arthur_children)
        self.assertIn(self.daughter, arthur_children)

        grandma_children = list(self.grandma.get_children())
        self.assertEqual(len(grandma_children), 1)
        self.assertIn(self.father, grandma_children)

    def test_spouses_query(self):
        """Arthur's spouse must be Eleanor, and Eleanor's spouse must be Arthur."""
        arthur_spouses = list(self.father.get_spouses())
        self.assertEqual(len(arthur_spouses), 1)
        self.assertIn(self.mother, arthur_spouses)

        eleanor_spouses = list(self.mother.get_spouses())
        self.assertEqual(len(eleanor_spouses), 1)
        self.assertIn(self.father, eleanor_spouses)

    def test_siblings_query(self):
        """Liam's sibling must be Grace, and Grace's sibling must be Liam."""
        liam_siblings = list(self.son.get_siblings())
        self.assertEqual(len(liam_siblings), 1)
        self.assertIn(self.daughter, liam_siblings)

        grace_siblings = list(self.daughter.get_siblings())
        self.assertEqual(len(grace_siblings), 1)
        self.assertIn(self.son, grace_siblings)
