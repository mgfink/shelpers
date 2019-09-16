{
  #read line  # ignore the header line
  IFS=,
  while read -r name role scope; do
   az role assignment delete --assignee $name --scope $scope
  done
} <assignments.csv
