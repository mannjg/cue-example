// Package services provides shared application templates and patterns
// This file defines the main #App template that applications instantiate
package services

import "list"

// #App is the main application template that apps instantiate.
// Apps provide their appName, and environments provide appConfig values.
// This template orchestrates the deployment and service creation.
//
// Usage in app files (e.g., foo.cue):
//   foo: #App & {
//       appName: "foo"
//   }
//
// Usage in environment files (e.g., dev.cue):
//   foo: appConfig: {
//       image: "foo:dev-latest"
//       replicas: 1
//       resources: {...}
//       ...
//   }
#App: {
	// ===== Required Fields =====
	// appName must be provided by the app definition file
	appName: string

	// ===== Default Values =====
	// App-level default namespace
	// Can be overridden by environment files via appConfig.namespace
	appNamespace: string | *"\(appName)-namespace"

	// Default labels applied to all resources
	// Merged with any labels provided via appConfig.labels
	defaultLabels: {
		app:        appName
		deployment: appName
	}

	// ===== Configuration Schema =====
	// appConfig must be satisfied by environment files
	// This is where all environment-specific configuration is provided
	appConfig: #AppConfig & {
		// Provide sensible defaults for optional fields
		namespace: string | *appNamespace
		labels: defaultLabels & {
			// Allow environments to add or override labels
			...
		}
	}

	// ===== Resource Generation =====
	// Instantiate the deployment template
	#DeploymentTemplate & {
		"appName":   appName
		"appConfig": appConfig
	}

	// Instantiate the service template
	#ServiceTemplate & {
		"appName":   appName
		"appConfig": appConfig
	}

	// Instantiate the debug service template (conditional on debug mode)
	#DebugServiceTemplate & {
		"appName":   appName
		"appConfig": appConfig
	}

	// ===== Resources List Management =====
	// resources_list defines which Kubernetes resources this app exports
	// Used by the generation tooling to know what to export
	// Automatically includes debugService when debug mode is enabled

	_baseResourcesList: ["deployment", "service"]

	// Default resources list - apps can override to add additional resources (e.g., bar adds "configmap")
	if appConfig.debug {
		resources_list: [...string] | *list.Concat([_baseResourcesList, ["debugService"]])
	}
	if !appConfig.debug {
		resources_list: [...string] | *_baseResourcesList
	}

	// ===== Extensibility =====
	// Allow apps to add additional fields (e.g., configmap for bar)
	// This is how apps can define additional Kubernetes resources
	...
}
