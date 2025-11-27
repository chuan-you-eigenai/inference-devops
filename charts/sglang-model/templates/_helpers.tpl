{{- define "sglang-model.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "sglang-model.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "sglang-model.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "sglang-model.labels" -}}
app: {{ include "sglang-model.fullname" . }}
{{- end }}

{{- define "sglang-model.selectorLabels" -}}
app: {{ include "sglang-model.fullname" . }}
{{- end }}
