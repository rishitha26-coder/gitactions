sed -i'' -e '/STUB/{' -e 'n;s/valueFrom:/value: \$\{\{ .Values.config.stub | quote \}\}/;n;s/configMapKeyRef:.*//g;n;s/name:.*//g;n;s/key: stub//g' -e '}' Charts/${1}/training/*/*.yaml  
