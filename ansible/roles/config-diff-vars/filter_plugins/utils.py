import jinja2
from ansible import errors


def _get_hostvar(context, var_name, inventory_hostname=None):
    if inventory_hostname is None:
        namespace = context
    else:
        if inventory_hostname not in context['hostvars']:
            raise errors.AnsibleFilterError(
                "Inventory hostname '%s' not in hostvars" % inventory_hostname)
        namespace = context["hostvars"][inventory_hostname]
    return namespace.get(var_name)

def _call_filter(context, filter_, value, *args, **kwargs):
    return context.environment.call_filter(filter_, value, args, kwargs, context=context)

def net_interface(context, host, network):
    return _call_filter(context, "net_interface", network, host)

def net_ip(context, host, network):
    return _call_filter(context, "net_ip", network, host)

def all_networks(context, host):
    return _get_hostvar(context, "network_interfaces", host)

def mappings2interfaces(ip_mappings):
    result = set()
    for descriptions in ip_mappings.values():
        for desc in descriptions:
            result.add(desc["interface"])
    return result

def should_prefix_fact(key):
    if key.startswith('ansible'):
        return False
    if key.startswith('_ansible'):
        return False
    if key == 'module_setup':
        return False
    if key == 'gather_subset':
        return False
    return True

def dummy_facts_prefix(facts, inject_facts):
    if not inject_facts:
       return facts
    result = {}
    for key in facts:
        if should_prefix_fact(key):
          result["ansible_%s" % key] = facts[key]
        else:
          result[key] = facts[key]
    return result

def interface_string(interface):
    return "\"{{ lookup('vars', inventory_hostname | replace('-', '_') ~ '_' ~ '" + interface + "') }}\""

@jinja2.contextfilter
def ip_mappings(context, hosts):
    hosts = set(hosts)
    result = {}
    for host in hosts:
        networks = all_networks(context, host)
        if not networks:
            continue
        result[host] = []
        for network in networks:
            interface = net_interface(context, host, network)
            ip = net_ip(context, host, network) or "dhcp.or.missing"
            result[host].append({
                'interface': interface,
                'ip': ip,
            })
    return result

@jinja2.contextfilter
def dummy_facts_interfaces(context, host):
   result = {}
   mappings = ip_mappings(context, [host]).get(host, [])
   interfaces = []
   for mapping in mappings:
       interface = mapping['interface']
       interfaces.append(interface)
       ip = mapping['ip']
       key = "ansible_%s" % interface
       value = {"ipv4": {"address": ip}}
       result[key] = value
   result['interfaces'] = result.get('interfaces',[]) + interfaces
   return result

class FilterModule(object):
    """General purpose filters."""

    def filters(self):
        return {
            'ip_mappings': ip_mappings,
            'mappings2interfaces': mappings2interfaces,
            'interface_string': interface_string,
            'dummy_facts_interfaces': dummy_facts_interfaces,
            'dummy_facts_prefix': dummy_facts_prefix,
        }
