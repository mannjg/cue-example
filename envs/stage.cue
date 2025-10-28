// Package envs provides staging environment configuration
// This file contains concrete values for staging instances
package envs

import (
	"example.com/cue-example/services"
)

// Import all from services to get deployment definitions
services

// Environment-level defaults shared by all apps in staging
// Apps can reference these values and override them if needed
_envDefaults: {
	clusterCAConfigMap: "stage-cluster-ca"
}

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

	// Override volume source names for staging environment
	volumeSourceNames: {
		configMapName: "foo-stage-config"
		secretName:    "foo-stage-secrets"
	}

	// Use environment-level cluster CA ConfigMap
	clusterCAConfigMap: _envDefaults.clusterCAConfigMap

	// Debug mode disabled for foo in staging (default is false)
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

	// Use environment-level cluster CA ConfigMap
	clusterCAConfigMap: _envDefaults.clusterCAConfigMap

	// Debug mode disabled for bar in staging (default is false)
}

// Staging environment configuration for baz app
baz: appConfig: {
	// Use stage-specific image tag
	image: "baz:stage-v1.2.3-rc1"

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

	// Use environment-level cluster CA ConfigMap
	clusterCAConfigMap: _envDefaults.clusterCAConfigMap

	// Enable debug mode for baz in staging for testing
	// Automatically adds debug port (5005) and creates separate debug service
	// Demonstrates that different apps can have different debug settings per environment
	debug: true
}
