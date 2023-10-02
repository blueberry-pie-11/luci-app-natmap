'use strict';
'require form';
'require fs';
'require rpc';
'require view';
'require tools.widgets as widgets';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getInstances() {
	return L.resolveDefault(callServiceList('natmap'), {}).then(function (res) {
		try {
			return res.natmap.instances || {};
		} catch (e) { }
		return {};
	});
}

function getStatus() {
	return getInstances().then(function (instances) {
		var promises = [];
		var status = {};
		for (var key in instances) {
			var i = instances[key];
			if (i.running && i.pid) {
				var f = '/var/run/natmap/' + i.pid + '.json';
				(function (k) {
					promises.push(fs.read(f).then(function (res) {
						status[k] = JSON.parse(res);
					}).catch(function (e) { }));
				})(key);
			}
		}
		return Promise.all(promises).then(function () { return status; });
	});
}

return view.extend({
	load: function () {
		return getStatus();
	},
	render: function (status) {
		var m, s, o;

		m = new form.Map('natmap', _('NATMap'));
		s = m.section(form.GridSection, 'natmap');
		s.addremove = true;
		s.anonymous = true;

		s.tab('general', _('General Settings'));
		s.tab('forward', _('Forward Settings'));
		s.tab('notify', _('Notify Settings'));
		s.tab('link', _('Link Settings'));

		o = s.option(form.DummyValue, '_nat_name', _('Name'));
		o.modalonly = false;
		o.textvalue = function (section_id) {
			var s = status[section_id];
			if (s) return s.name;
		};

		o = s.taboption('general', form.Value, 'nat_name', _('Name'));
		o.datatype = 'string';
		o.modalonly = true;

		o = s.taboption('general', form.ListValue, 'nat_protocol', _('Protocol'));
		o.default = '0';
		o.value('0', 'TCP');
		o.value('1', 'UDP');
		o.textvalue = function (section_id) {
			var cval = this.cfgvalue(section_id);
			var i = this.keylist.indexOf(cval);
			return this.vallist[i];
		};

		o = s.taboption('general', form.ListValue, 'ip_address_family', _('Restrict to address family'));
		o.modalonly = true;
		o.value('', _('IPv4 and IPv6'));
		o.value('ipv4', _('IPv4 only'));
		o.value('ipv6', _('IPv6 only'));

		o = s.taboption('general', widgets.NetworkSelect, 'wan_interface', _('Wan_Interface'));
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'interval', _('Keep-alive interval'));
		o.datatype = 'uinteger';
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'stun_server', _('STUN server'));
		o.datatype = 'host';
		o.modalonly = true;
		o.optional = false;
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'http_server', _('HTTP server'), _('For TCP mode'));
		o.datatype = 'host';
		o.modalonly = true;
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'bind_port', _('Bind port'));
		o.datatype = 'port';
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'notify_script', _('Notify script'));
		o.datatype = 'file';
		o.modalonly = true;

		//
		// 
		// forward
		o = s.taboption('forward', form.Flag, 'forward_enable', _('Forward Enable'));
		o.default = false;
		o.modalonly = true;

		o = s.taboption('forward', form.ListValue, 'forward_mode', _('Forward mode'));
		o.default = 'local';
		o.value('local', _('local'));
		o.value('ikuai', _('ikuai'));
		o.depends('forward_enable', '1');

		// forward_natmap
		o = s.taboption('forward', form.Value, 'forward_target_ip', _('Forward target'));
		o.datatype = 'host';
		o.modalonly = true;
		o.depends('forward_mode', 'local');
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Value, 'forward_target_port', _('Forward target port'), _('0 will forward to the out port get from STUN'));
		o.datatype = 'port';
		o.modalonly = true;
		o.depends('forward_mode', 'local');
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', widgets.NetworkSelect, 'forward_target_interface', _('Target_Interface'));
		o.modalonly = true;
		o.depends('forward_mode', 'local');

		o = s.taboption('forward', form.Flag, 'forward_use_natmap', _('Forward use natmap'));
		o.default = false;
		o.modalonly = true;
		o.depends('forward_mode', 'local');

		// forward_ikuai
		o = s.taboption('forward', form.Value, 'forward_ikuai_web_url', _('Ikuai Web URL'), _('such as http://127.0.0.1:8080'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Value, 'forward_ikuai_username', _('Ikuai Username'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Value, 'forward_ikuai_password', _('Ikuai Password'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.ListValue, 'forward_ikuai_mapping_protocol', _('Ikuai Mapping Protocol'));
		o.modalonly = true;
		o.value('tcp+udp', _('TCP+UDP'));
		o.value('tcp', _('TCP'));
		o.value('udp', _('UDP'));
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Value, 'forward_ikuai_mapping_wan_interface', _('Ikuai Mapping Wan Interface'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('forward_mode', 'ikuai');

		//
		// 
		// notify
		o = s.taboption('notify', form.Flag, 'notify_enable', _('Notify'));
		o.default = false;
		o.modalonly = true;

		o = s.taboption('notify', form.ListValue, 'notify_channel', _('Notify channel'));
		o.default = 'telegram_bot';
		o.modalonly = true;
		o.value('telegram_bot', _('Telegram Bot'));
		o.value('pushplus', _('PushPlus'));
		o.depends('notify_enable', '1');

		o = s.taboption('notify', form.Value, 'notify_channel_telegram_bot_chat_id', _('Chat ID'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'notify_channel_telegram_bot_token', _('Token'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'notify_channel_telegram_bot_proxy', _('http proxy'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'notify_channel_pushplus_token', _('Token'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'pushplus');

		// link
		o = s.taboption('link', form.Flag, 'link_enable', _('Change another service\'s config'));
		o.modalonly = true;
		o.ucioption = 'link_mode';
		o.load = function (section_id) {
			return this.super('load', section_id) ? '1' : '0';
		};
		o.write = function (section_id, formvalue) { };

		o = s.taboption('link', form.ListValue, 'link_mode', _('Service'));
		o.default = 'qbittorrent';
		o.modalonly = true;
		o.value('emby', _('Emby'));
		o.value('qbittorrent', _('qBittorrent'));
		o.value('transmission', _('Transmission'));
		o.value('cloudflare_origin_rule', _('Cloudflare Origin Rule'));
		o.value('cloudflare_redirect_rule', _('Cloudflare Redirect Rule'));
		o.depends('link_enable', '1');

		o = s.taboption('link', form.Value, 'cloudflare_email', _('Email'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'cloudflare_api_key', _('API Key'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'cloudflare_zone_id', _('Zone ID'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'cloudflare_rule_name', _('Rule Name'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'cloudflare_rule_target_url', _('Target URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'emby_url', _('URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		o = s.taboption('link', form.Value, 'emby_api_key', _('API Key'));
		o.datatype = 'host';
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		o = s.taboption('link', form.Flag, 'emby_use_https', _('Update HTTPS Port'), _('Set to False if you want to use HTTP'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		o = s.taboption('link', form.Flag, 'emby_update_host_with_ip', _('Update host with IP'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		o = s.taboption('link', form.Value, 'qb_web_ui_url', _('Web UI URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'qb_username', _('Username'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'qb_password', _('Password'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Flag, 'qb_allow_ipv6', _('Allow IPv6'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'qb_ipv6_address', _('IPv6 Address'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('qb_allow_ipv6', '1');

		o = s.taboption('link', form.Value, 'tr_rpc_url', _('RPC URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Value, 'tr_username', _('Username'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Value, 'tr_password', _('Password'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Flag, 'tr_allow_ipv6', _('Allow IPv6'));
		o.modalonly = true;
		o.default = false;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Value, 'tr_ipv6_address', _('IPv6 Address'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('tr_allow_ipv6', '1');

		o = s.option(form.DummyValue, '_external_ip', _('External IP'));
		o.modalonly = false;
		o.textvalue = function (section_id) {
			var s = status[section_id];
			if (s) return s.ip;
		};

		o = s.option(form.DummyValue, '_external_port', _('External Port'));
		o.modalonly = false;
		o.textvalue = function (section_id) {
			var s = status[section_id];
			if (s) return s.port;
		};

		o = s.option(form.Flag, 'natmap_enable', _('ENABLE NATMap'));
		o.editable = true;
		o.modalonly = false;

		return m.render();
	}
});
