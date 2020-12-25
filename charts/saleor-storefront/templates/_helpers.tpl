{{/*
Expand the name of the chart.
*/}}
{{- define "saleor-storefront.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "saleor-storefront.fullname" -}}
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
{{- define "saleor-storefront.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "saleor-storefront.labels" -}}
helm.sh/chart: {{ include "saleor-storefront.chart" . }}
{{ include "saleor-storefront.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "saleor-storefront.selectorLabels" -}}
app.kubernetes.io/name: {{ include "saleor-storefront.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "saleor-storefront.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "saleor-storefront.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate standard environment configuration.
*/}}
{{- define "saleor-storefront.env" -}}
env:
{{- if .Values.staticUrl }}
  - name: STATIC_URL
    value: {{ .Values.staticUrl | quote }}
{{- else }}
  - name: STATIC_URL
    value: ""
{{- end }}
{{- if .Values.saleorChannelSlug }}
  - name: SALEOR_CHANNEL_SLUG
    value: {{ .Values.saleorChannelSlug | quote }}
{{- else }}
  - name: SALEOR_CHANNEL_SLUG
    value: "default-channel"
{{- end }}
{{- if .Values.externalServices.sentry.enabled }}
  - name: SENTRY_DSN
    value: {{ .Values.externalServices.sentry.dsn | quote }}
  - name: SENTRY_APM
    value: {{ .Values.externalServices.sentry.samplingRate | quote }}
{{- end }}
{{- if and .Values.externalServices.googleTagManager.enabled .Values.externalServices.googleTagManager.id }}
  - name: GTM_ID
    value: {{ .Values.externalServices.googleTagManager.id | quote }}
{{- end }}
{{- if .Values.demoMode }}
  - name: DEMO_MODE
    value: {{ .Values.demoMode | quote }}
{{- else }}
  - name: DEMO_MODE
    value: "false"
{{- end }}
{{- if .Values.apiUrl }}
  - name: API_URI
    value: {{ .Values.apiUrl | quote }}
{{- else }}
  - name: API_URI
    value: {{ cat (cat "https://core." (.Values.ingress.hosts | first).host) "/graphql/" | nospace }}
{{- end }}
{{- end }}
