//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <agent_dart/agent_dart_plugin.h>
#include <agent_dart_auth/agent_dart_auth_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) agent_dart_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AgentDartPlugin");
  agent_dart_plugin_register_with_registrar(agent_dart_registrar);
  g_autoptr(FlPluginRegistrar) agent_dart_auth_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AgentDartAuthPlugin");
  agent_dart_auth_plugin_register_with_registrar(agent_dart_auth_registrar);
}
