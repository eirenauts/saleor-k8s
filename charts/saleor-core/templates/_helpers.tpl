{{/*
Expand the name of the chart.
*/}}
{{- define "saleor-core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "saleor-core.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "saleor-core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "saleor-core.labels" -}}
helm.sh/chart: {{ include "saleor-core.chart" . }}
{{ include "saleor-core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common Selector labels
*/}}
{{- define "saleor-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "saleor-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Worker Container name
*/}}
{{- define "saleor-core.workerContainerName" -}}
{{ include "saleor-core.name" . }}-worker
{{- end }}

{{/*
Api Container name
*/}}
{{- define "saleor-core.apiContainerName" -}}
{{ include "saleor-core.name" . }}-api
{{- end }}

{{/*
Web Container name
*/}}
{{- define "saleor-core.webContainerName" -}}
{{ include "saleor-core.name" . }}-web
{{- end }}

{{/*
Job Container name
*/}}
{{- define "saleor-core.jobContainerName" -}}
{{ include "saleor-core.name" . }}-job
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "saleor-core.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "saleor-core.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate standard environment configuration.
*/}}
{{- define "saleor-core.env" -}}
{{- $smtp := .Values.externalServices.email.smtpSettings }}
envFrom:
  - configMapRef:
      name: {{ include "saleor-core.fullname" . }}
  - secretRef:
    {{- if not .Values.existingSecret }}
      name: {{ include "saleor-core.fullname" . }}
    {{- else }}
      name: {{ .Values.existingSecret }}
    {{- end }}
env:
{{- if .Values.existingSecret }}
  - name: SECRET_KEY
    value: "$(SALEOR_SECRET_KEY)"
  - name: RESTIC_PASSWORD
    value: ""
  - name: RESTIC_S3_ACCESS_KEY_ID
    value: ""
  - name: RESTIC_S3_SECRET_ACCESS_KEY
    value: ""
{{- end }}
{{- if and .Values.jobs.init.plugins.enabled .Values.externalServices.vatLayer.enabled }}
  - name: VATLAYER_API_KEY
    value: "$(VATLAYER_API_KEY)"
{{- else }}
  - name: VATLAYER_API_KEY
    value: ""
{{- end }}
{{- if and .Values.jobs.init.plugins.enabled .Values.externalServices.braintree.enabled }}
  - name: BRAINTREE_PRIVATE_KEY
    value: "$(BRAINTREE_PRIVATE_KEY)"
{{- else }}
  - name: BRAINTREE_PRIVATE_KEY
    value: ""
{{- end }}
{{- if and "$(REDIS_PASSWORD)" .Values.externalServices.redis.tls }}
  - name: REDIS_URL
    value: "rediss://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB_NUMBER)"
  - name: CELERY_BROKER_URL
    value: "rediss://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(CELERY_BROKER_DB_NUMBER)"
{{- else if and "$(REDIS_PASSWORD)" (not .Values.externalServices.redis.tls) }}
  - name: REDIS_URL
    value: "redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB_NUMBER)"
  - name: CELERY_BROKER_URL
    value: "redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(CELERY_BROKER_DB_NUMBER)"
{{- else if not "$(REDIS_PASSWORD)" }}
  - name: REDIS_URL
    value: "redis://$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB_NUMBER)"
  - name: CELERY_BROKER_URL
    value: "redis://$(REDIS_HOST):$(REDIS_PORT)/$(CELERY_BROKER_DB_NUMBER)"
{{- end }}
{{- if .Values.externalServices.postgresql.requireSSL }}
  - name: DATABASE_URL
    value: "postgres://$(POSTGRESQL_USER):$(POSTGRESQL_PASSWORD)@$(POSTGRESQL_HOST):$(POSTGRESQL_PORT)/$(POSTGRESQL_DATABASE)?sslmode=verify-full"
{{- else if not .Values.externalServices.postgresql.requireSSL }}
  - name: DATABASE_URL
    value: "postgres://$(POSTGRESQL_USER):$(POSTGRESQL_PASSWORD)@$(POSTGRESQL_HOST):$(POSTGRESQL_PORT)/$(POSTGRESQL_DATABASE)"
{{- end }}
{{- if $smtp.generic.enabled }}
  - name: EMAIL_URL
    value: "smtp://{{ $smtp.generic.loginName }}@{{ $smtp.generic.customDomainName }}:$(EMAIL_PASSWORD)@{{ $smtp.generic.providerDomainName }}:{{ $smtp.generic.port }}/{{ $smtp.generic.extraArgs }}"
{{- else if $smtp.mailjet.enabled }}
  - name: EMAIL_URL
    value: "smtp://{{ $smtp.mailjet.username }}:$(EMAIL_PASSWORD)@in-v3.mailjet.com:587/?tls=True"
{{- else if $smtp.amazonSES.enabled }}
  - name: EMAIL_URL
    value: "smtp://{{ $smtp.amazonSES.username }}:$(EMAIL_PASSWORD)@email-smtp.{{ $smtp.amazonSES.region }}.amazonaws.com:587/?tls=True"
{{- end }}
{{- end }}


{{/*
Generate backup configuration
*/}}
{{- define "saleor-core.env.backup" -}}
{{- if or .Values.backup.database.enabled .Values.backup.media.enabled }}
  - name: RESTIC_PASSWORD
    valueFrom:
      secretKeyRef:
      {{- if not .Values.existingSecret }}
        name: {{ include "saleor-core.fullname" . }}
      {{- else }}
        name: {{ .Values.existingSecret }}
      {{- end }}
        key: RESTIC_PASSWORD
  - name: RESTIC_S3_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
      {{- if not .Values.existingSecret }}
        name: {{ include "saleor-core.fullname" . }}
      {{- else }}
        name: {{ .Values.existingSecret }}
      {{- end }}
        key: RESTIC_S3_ACCESS_KEY_ID
  - name: RESTIC_S3_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
      {{- if not .Values.existingSecret }}
        name: {{ include "saleor-core.fullname" . }}
      {{- else }}
        name: {{ .Values.existingSecret }}
      {{- end }}
        key: RESTIC_S3_SECRET_ACCESS_KEY
{{- end }}
{{- end }}


{{/*
A script to check if the saleor-postgresql service is ready
*/}}
{{- define "saleor.postgresql.isReady" -}}
function is_pg_ready {
  pg_isready \
    --host=$(POSTGRESQL_HOST) \
    --port=$(POSTGRESQL_PORT) \
    --username=$(POSTGRESQL_USER) \
    --dbname=$(POSTGRESQL_PASSWORD)
}

while [[ "$(is_pg_ready)" != *"accepting connections"* ]]; do
  echo "response from server: $(is_pg_ready)";
  echo "waiting for $(POSTGRESQL_HOST) service" && sleep 5s;
done

echo "$(is_pg_ready)"
echo "$(POSTGRESQL_HOST) is ready"
{{- end -}}

{{/*
A script to check if the redis service is ready
*/}}
{{- define "saleor.redis.isReady" -}}

#!/bin/bash

function redis_status {
  redis-cli --no-auth-warning -u "$(REDIS_URL)" ping
}

while [[ "$(redis_status)" != "PONG" ]]; do
  echo "waiting for $(REDIS_HOST) to return PONG" && sleep 5s;
done

echo "redis current ping response: $(redis_status)"
{{- end -}}
