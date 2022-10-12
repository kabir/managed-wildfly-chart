{{/*
Returns the builder image to use, depending on '.Values.builder.mode'. If it is:
    - 'populated', we use the image indicated by '.Values.builder.images.managedServerBase'
    - not set, we use the image
*/}}
{{- define "common.wildfly.image.builder" }}
{{- if eq .Values.builder.mode "populated" -}}
{{ .Values.builder.images.managedServerBase }}
{{- else -}}
{{ .Values.builder.images.managedServer }}
{{- end }}
{{- end }}
