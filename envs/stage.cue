// Package envs provides staging environment configuration
// This file contains concrete values for staging instances
package envs

import (
	"example.com/cue-example/services"
)

// Import all from services to get deployment definitions
services

// Staging environment configuration for foo app
// Production-like environment for testing and validation before promoting to production
foo: appConfig: {
	// Use stage-specific image tag - typically built from release candidate or main branch
	image: "foo:stage-v1.2.3-rc1"

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
}

// Staging environment configuration for bar app
bar: appConfig: {
	// Use stage-specific image tag
	image: "bar:stage-v1.2.3-rc1"

	// Multiple replicas for high availability testing
	replicas: 2

	// Moderate resources
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
}
