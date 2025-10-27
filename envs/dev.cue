// Package envs provides development environment configuration
// This file contains concrete values for development instances
package envs

import (
	"example.com/cue-example/services"
)

// Import all from services to get deployment definition
services

// Development environment configuration
// Optimized for fast iteration and minimal resource usage
appConfig: {
	// Use latest dev image for rapid iteration
	image: "myapp:dev-latest"

	// Single replica for development
	replicas: 1

	// Minimal resources for development
	// Suitable for local clusters (minikube, kind) or shared dev clusters
	resources: {
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "200m"
			memory: "256Mi"
		}
	}

	// Development namespace
	namespace: "dev"

	// No node selector - can run on any node
	// nodeSelector not specified, runs anywhere
}
