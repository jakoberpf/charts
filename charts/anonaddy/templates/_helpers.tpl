{{/*
Expand the name of the chart.
*/}}
{{- define "anonaddy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "anonaddy.fullname" -}}
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
{{- define "anonaddy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "anonaddy.labels" -}}
helm.sh/chart: {{ include "anonaddy.chart" . }}
{{ include "anonaddy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "anonaddy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "anonaddy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "anonaddy.selectorLabelsMariaDB" -}}
app.kubernetes.io/name: {{ include "anonaddy.name" . }}-mariadb
app.kubernetes.io/instance: {{ .Release.Name }}-mariadb
{{- end }}

{{- define "anonaddy.selectorLabelsRedis" -}}
app.kubernetes.io/name: {{ include "anonaddy.name" . }}-redis
app.kubernetes.io/instance: {{ .Release.Name }}-redis
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "anonaddy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "anonaddy.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
