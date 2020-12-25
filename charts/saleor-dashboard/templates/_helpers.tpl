{{/*
Expand the name of the chart.
*/}}
{{- define "saleor-dashboard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "saleor-dashboard.fullname" -}}
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
{{- define "saleor-dashboard.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "saleor-dashboard.labels" -}}
helm.sh/chart: {{ include "saleor-dashboard.chart" . }}
{{ include "saleor-dashboard.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "saleor-dashboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "saleor-dashboard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "saleor-dashboard.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "saleor-dashboard.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate standard environment configuration.
*/}}
{{- define "saleor-dashboard.env" -}}
env:
{{- if .Values.staticUrl }}
  - name: STATIC_URL
    value: {{ .Values.staticUrl | quote }}
{{- else }}
  - name: STATIC_URL
    value: ""
{{- end }}
{{- if .Values.apiUrl }}
  - name: API_URI
    value: {{ .Values.apiUrl | quote }}
{{- else }}
  - name: API_URI
    value: {{ cat (cat "https://core." ((.Values.ingress.hosts | first).host | replace "dashboard." "")) "/graphql/" | nospace }}
{{- end }}
{{- if .Values.apiMountUri }}
  - name: APP_MOUNT_URI
    value: {{ .Values.apiMountUri | quote }}
{{- else }}
  - name: APP_MOUNT_URI
    value: {{ cat (cat "https://dashboard." ((.Values.ingress.hosts | first).host | replace "dashboard." "")) "/" | nospace }}
{{- end }}
{{- end }}
