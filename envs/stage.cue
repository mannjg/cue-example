// Package envs provides staging environment configuration
// This file contains concrete values for staging instances
package envs

import svc "example.com/cue-example/services"

// Import the services package to get deployment and appConfig schema
svc

// Staging environment configuration
// Production-like environment for testing and validation
// before promoting to production
appConfig: {
	// Use stage-specific image tag
	// Typically built from release candidate or main branch
	image: "myapp:stage-v1.2.3-rc1"

	// Multiple replicas for high availability testing
	replicas: 2

	// Moderate resources - production-like but more conservative
	// Allows for realistic performance testing
	resources: {
		requests: {
			cpu:    "250m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "500m"
			memory: "1Gi"
		}
	}

	// Staging namespace
	namespace: "staging"

	// Optional: run on specific node pool if available
	// Uncomment if your cluster has dedicated staging nodes
	// nodeSelector: {
	// 	"environment": "staging"
	// 	"workload":    "general"
	// }
}
