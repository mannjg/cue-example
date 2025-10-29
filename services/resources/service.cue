// Package services provides shared application templates and patterns
// This file defines the Service resource templates
package resources

import (
	"list"

	"example.com/cue-example/k8s"
	base "example.com/cue-example/services/base"
)

// #ServiceTemplate generates a Kubernetes Service from app configuration.
#ServiceTemplate: {
	// Required inputs
	appName:   string
	appConfig: base.#AppConfig

	// Default labels (can be extended via appConfig.labels)
	_defaultLabels: {
		app:        appName
		deployment: appName
	}

	// Computed labels - merge defaults with config
	_labels: _defaultLabels & appConfig.labels

	// The actual Service resource
	service: k8s.#Service & {
		metadata: {
			name:      appName
			namespace: appConfig.namespace
			labels:    _labels
			if appConfig.serviceAnnotations != _|_ {
				annotations: appConfig.serviceAnnotations
			}
		}

		spec: {
			type: base.#DefaultServiceType

			selector: base.#DefaultServiceSelector & {
				app: appName
			}

			// Service ports - always include base ports, plus additional
			_baseServicePorts: [base.#DefaultHttpServicePort]
			ports: list.Concat([_baseServicePorts, appConfig.additionalServicePorts])

			sessionAffinity: base.#DefaultSessionAffinity
		}
	}
}

// #DebugServiceTemplate generates a debug-only Service when debug mode is enabled.
// This provides external access to the debug port (e.g., Java remote debugging on port 5005).
#DebugServiceTemplate: {
	// Required inputs
	appName:   string
	appConfig: base.#AppConfig

	// Default labels (can be extended via appConfig.labels)
	_defaultLabels: {
		app:        appName
		deployment: appName
	}

	// Computed labels - merge defaults with config
	_labels: _defaultLabels & appConfig.labels

	// The debug Service resource (only created if debug mode is enabled)
	if appConfig.debug {
		debugService: k8s.#Service & {
			metadata: {
				name:      "\(appName)-debug"
				namespace: appConfig.namespace
				labels:    _labels
				annotations: {
					"description": "Debug service for remote debugging"
				}
			}

			spec: {
				type: base.#DefaultServiceType

				selector: base.#DefaultServiceSelector & {
					app: appName
				}

				ports: [base.#DefaultDebugServicePort]

				sessionAffinity: base.#DefaultSessionAffinity
			}
		}
	}
}
