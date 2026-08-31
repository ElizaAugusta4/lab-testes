{{- define "generic-app.fullname" -}}
{{- .Values.nameOverride | default .Chart.Name -}}
{{- end -}}

{{- define "generic-app.labels" -}}
app: {{ include "generic-app.fullname" . }}
{{- end -}}
