ENVIRONMENT="${1:-staging}"

shopt -s extglob
for chart in Charts/* ; do
  grep -q '  replicas: {{ $.Values.config.min_replicas }}' ${chart}/templates/*.yaml || \
    grep -q '  replicas: {{ $.Values.config.minReplicaCount }}' ${chart}/templates/*.yaml || continue
  rm -f ${chart}/${ENVIRONMENT}/templates
  mkdir ${chart}/${ENVIRONMENT}/templates 
  for template in ${chart}/templates/*.yaml  ; do
    sed -e 's;  replicas: {{ $.Values.config.min_replicas }};  {{ if not .Values.autoscaling.enabled }}replicas: {{ $.Values.config.min_replicas }}{{ end }};g' \
        -e 's;  replicas: {{ $.Values.config.minReplicaCount }};  {{ if not .Values.autoscaling.enabled }}replicas: {{ $.Values.config.minReplicaCount }}{{ end }};g' $template > ${template//templates/${ENVIRONMENT}/templates}
  done
done
