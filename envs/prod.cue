// Package envs provides production environment configuration
// This file contains concrete values for production instances
package envs

import (
	"example.com/cue-example/services"
)

// Import all from services to get deployment definition
services

// Production environment configuration
// Optimized for reliability, performance, and high availability
appConfig: {
	// Use specific versioned image tag for production
	// Never use 'latest' or floating tags in production
	image: "myapp:v1.2.3"

	// Multiple replicas for high availability
	// Ensures service continuity during rolling updates and node failures
	replicas: 3

	// Production-grade resources
	// Sized based on actual load testing and monitoring data
	resources: {
		requests: {
			cpu:    "500m"
			memory: "1Gi"
		}
		limits: {
			cpu:    "1000m"
			memory: "2Gi"
		}
	}

	// Production namespace
	namespace: "production"

	// Node selector to run on production-grade nodes
	// Ensures production workloads run on dedicated, reliable hardware
	nodeSelector: {
		"environment": "production"
		"workload":    "application"
		// Example: might also select nodes with SSD storage
		// "storage": "ssd"
	}
}

// Production-specific overrides to base deployment configuration
// These could include additional production requirements
// Since services is already imported above, we can directly override deployment fields
deployment: {
	// Add production-specific annotations
	metadata: annotations: {
		"deployment.kubernetes.io/revision": "1"
		"maintainer":                        "platform-team@example.com"
		"cost-center":                       "engineering"
	}

	spec: {
		// More conservative rolling update for production
		strategy: rollingUpdate: {
			maxSurge:       1
			maxUnavailable: 0  // Zero downtime deployments
		}

		template: {
			// Add production-specific pod annotations
			metadata: annotations: {
				"backup.velero.io/backup-volumes": "data"
				"sidecar.istio.io/inject":          "true"  // If using service mesh
			}

			spec: {
				// Production pods get higher priority
				// priorityClassName: "production-high"

				// Spread pods across zones for high availability
				// Uncomment if your cluster has topology labels
				// affinity: podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [{
				// 	weight: 100
				// 	podAffinityTerm: {
				// 		labelSelector: matchLabels: {
				// 			app: "myapp"
				// 		}
				// 		topologyKey: "topology.kubernetes.io/zone"
				// 	}
				// }]
			}
		}
	}
}
