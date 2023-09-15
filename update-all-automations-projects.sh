for a in ~/repos/automations/* ; do
     cd $a || continue 
     service=${a##*/}
     service=${service//_/-}
     echo ${service}: 
     tags=$(git tag --points-at $(git rev-parse head))
     deployed=$(kubectl --context=soa-shared-legacy -n mogo-dev get deployment/${service} -o json | \
         jq -r '.spec.template.spec.containers[0].image' | cut -d : -f 2 )
     for tag in ${tags} ; do
        [[ "$tag" == "$deployed" ]] && echo $tag = $deployed && continue 2
     done
     echo "Deployed: $deployed, tag: $tag" ; echo "deploy new tag?"
     read -n 1 answer
     [[ "$answer" == @(y|Y) ]] || continue
     ~/repos/soa-helm-charts/scripts/somogoCommitDeploy.sh --force
     sleep 60s
done
