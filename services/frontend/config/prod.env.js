'use strict'
module.exports = {
  NODE_ENV: '"production"',
  // NOTE: In minikube this part get's evaluated to the hostname:
  // "http://dev.k8s/api/" from kubernetes -> frontend-secrets -> ROOT_API
  ROOT_API: JSON.stringify(process.env.ROOT_API)
}
