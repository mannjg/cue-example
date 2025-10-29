// Package envs provides staging environment configuration
// This file contains concrete values for staging instances
package envs

import (
	svc "example.com/cue-example/services"
)

// Bring service definitions into this package with explicit references
foo: svc.foo
bar: svc.bar
baz: svc.baz

// Environment-level defaults shared by all apps in staging
// Apps can reference these values and override them if needed
_envDefaults: {
	clusterCAConfigMap: "stage-cluster-ca"
	namespace:          "staging"
	replicas:           2

	// Common staging resource limits - production-like but more conservative
	resources: svc.#DefaultStageResources
}

// Staging environment configuration for foo app
// Production-like environment for testing and validation before promoting to production
foo: appConfig: {
	// Use stage-specific image tag - typically built from release candidate or main branch
	image: "foo:stage-v1.2.3-rc1"

	// Use environment-level defaults for common settings
	_envDefaults

	// Override volume source names for staging environment
	volumeSourceNames: {
		configMapName: "foo-stage-config"
		secretName:    "foo-stage-secrets"
	}

	// Debug mode disabled for foo in staging (default is false)
}

// Staging environment configuration for bar app
bar: {
	appConfig: {
		// Use stage-specific image tag
		image: "bar:stage-v1.2.3-rc1"

		// Use environment-level defaults for common settings
		_envDefaults

		// Debug mode disabled for bar in staging (default is false)
	}

	// Provide ConfigMap metadata
	resources: configmap: metadata: {
		namespace: "staging"
		labels: {
			app:        "bar"
			deployment: "bar"
		}
	}
}

// Staging environment configuration for baz app
baz: appConfig: {
	// Use stage-specific image tag
	image: "baz:stage-v1.2.3-rc1"

	// Use environment-level defaults for common settings
	_envDefaults

	// Enable debug mode for baz in staging for testing
	// Automatically adds debug port (5005) and creates separate debug service
	// Demonstrates that different apps can have different debug settings per environment
	debug: true
}
