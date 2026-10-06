from django.db import transaction
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from rest_framework import serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from .models import ContentReport, Person, FamilyTree
from .permissions import can_access_tree


class ReportInput(serializers.Serializer):
    person_id = serializers.IntegerField(min_value=1)
    reason = serializers.ChoiceField(choices=['PRIVACY', 'INCORRECT', 'INAPPROPRIATE', 'OTHER'])
    details = serializers.CharField(max_length=2000)
    request_key = serializers.CharField(max_length=80)


def report_data(report):
    return {name: getattr(report, name) for name in ('id', 'reason', 'details', 'status', 'response', 'created_at', 'updated_at')}


class ContentReportView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'content_report'
    def get(self, request):
        return Response({'reports': [report_data(r) for r in ContentReport.objects.filter(reporter=request.user).order_by('-created_at')[:100]]})
    def post(self, request):
        form = ReportInput(data=request.data)
        form.is_valid(raise_exception=True)
        values = form.validated_data
        with transaction.atomic():
            get_object_or_404(get_user_model().objects.select_for_update(), pk=request.user.pk)
            previous = ContentReport.objects.filter(reporter=request.user, request_key=values['request_key']).first()
            if previous:
                if (previous.person_id != values['person_id'] or previous.reason != values['reason'] or previous.details != values['details']):
                    return Response({'detail': 'This submission was already used. Start a new report.'}, status=409)
                return Response(report_data(previous), status=200)
            person = get_object_or_404(Person, pk=values['person_id'])
            tree = get_object_or_404(FamilyTree.objects.select_for_update(), pk=person.family_tree_id)
            if not can_access_tree(request.user, tree):
                from rest_framework.exceptions import NotFound
                raise NotFound()
            person = get_object_or_404(Person, pk=person.pk, family_tree=tree)
            report = ContentReport.objects.create(reporter=request.user, tree=tree, person=person,
                reason=values['reason'], details=values['details'], request_key=values['request_key'])
        return Response(report_data(report), status=status.HTTP_201_CREATED)
