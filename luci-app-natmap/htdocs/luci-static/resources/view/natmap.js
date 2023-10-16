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
		s.tab('custom', _('Custom Settings'))

		o = s.option(form.Flag, 'natmap_enable', _('ENABLE'));
		o.editable = true;
		o.modalonly = false;

		o = s.option(form.DummyValue, '_nat_name', _('Name'));
		o.modalonly = false;
		o.textvalue = function (section_id) {
			var s = status[section_id];
			if (s) return s.name;
		};

		o = s.taboption('general', form.Value, 'general_nat_name', _('Name'));
		o.datatype = 'string';
		o.modalonly = true;

		o = s.taboption('general', form.ListValue, 'general_nat_protocol', _('Protocol'));
		o.default = 'tcp';
		o.value('tcp', _('TCP'));
		o.value('udp', _('UDP'));
		// o.textvalue = function (section_id) {
		// 	var cval = this.cfgvalue(section_id);
		// 	var i = this.keylist.indexOf(cval);
		// 	return this.vallist[i];
		// };

		o = s.taboption('general', form.ListValue, 'general_ip_address_family', _('Restrict to address family'));
		o.modalonly = true;
		o.value('', _('IPv4 and IPv6'));
		o.value('ipv4', _('IPv4 only'));
		o.value('ipv6', _('IPv6 only'));

		o = s.taboption('general', widgets.NetworkSelect, 'general_wan_interface', _('Wan Interface'));
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'general_interval', _('Keep-alive interval'));
		o.datatype = 'uinteger';
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'general_stun_server', _('STUN server'));
		o.datatype = 'host';
		o.modalonly = true;
		o.optional = false;
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'general_http_server', _('HTTP server'), _('For TCP mode'));
		o.datatype = 'host';
		o.modalonly = true;
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'general_bind_port', _('Bind port'));
		o.datatype = 'port';
		o.rmempty = false;

		// ----------------------------------------
		// forward
		o = s.taboption('forward', form.Flag, 'forward_enable', _('Enable Forward'));
		o.ucioption = 'forward_mode';
		o.default = false;
		o.modalonly = true;

		o = s.taboption('forward', form.ListValue, 'forward_mode', _('Forward mode'));
		// o.modalonly = false;
		o.default = 'firewall';
		o.value('firewall', _('firewall dnat'));
		o.value('natmap', _('natmap'));
		o.value('ikuai', _('ikuai'));
		o.depends('forward_enable', '1');

		// forward_natmap
		o = s.taboption('forward', form.Value, 'forward_target_ip', _('Forward target'));
		o.datatype = 'host';
		o.modalonly = true;
		o.depends('forward_mode', 'firewall');
		o.depends('forward_mode', 'natmap');
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Value, 'forward_target_port', _('Forward target port'), _('0 will forward to the out port get from STUN'));
		o.datatype = 'port';
		o.modalonly = true;
		o.depends('forward_mode', 'firewall');
		o.depends('forward_mode', 'natmap');
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', widgets.NetworkSelect, 'forward_natmap_target_interface', _('Target_Interface'));
		o.modalonly = true;
		o.depends('forward_mode', 'firewall');

		// forward_ikuai
		o = s.taboption('forward', form.Value, 'forward_ikuai_web_url', _('Ikuai Web URL'), _('such as http://127.0.0.1:8080 or http://ikuai.lan:8080.if use host,must close Rebind protection in DHCP and DNS'));
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

		o = s.taboption('forward', form.ListValue, 'forward_ikuai_mapping_protocol', _('Ikuai Mapping Protocol'), _('such as tcp or udp or tcp+udp'));
		o.modalonly = true;
		o.value('tcp+udp', _('TCP+UDP'));
		o.value('tcp', _('TCP'));
		o.value('udp', _('UDP'));
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Value, 'forward_ikuai_mapping_wan_interface', _('Ikuai Mapping Wan Interface'), _('such as adsl_1 or wan'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Flag, 'forward_ikuai_advanced_enable', _('Ikuai Advanced Settings'));
		o.default = false;
		o.modalonly = true;
		o.depends('forward_mode', 'ikuai');

		o = s.taboption('forward', form.Value, 'forward_ikuai_max_retries', _('Max Retries'), _('max retries,default 0 means execute only once'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('forward_ikuai_advanced_enable', '1');

		o = s.taboption('forward', form.Value, 'forward_ikuai_sleep_time', _('Sleep Time'), _('Single sleep time, unit is seconds, default 0 is 3 seconds'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('forward_ikuai_advanced_enable', '1');

		//
		// 
		// notify
		o = s.taboption('notify', form.Flag, 'notify_enable', _('Enable Notify'));
		o.ucioption = 'notify_channel';
		o.default = false;
		o.modalonly = true;

		o = s.taboption('notify', form.ListValue, 'notify_channel', _('Notify channel'));
		o.default = 'telegram_bot';
		o.modalonly = true;
		o.value('telegram_bot', _('Telegram Bot'));
		o.value('pushplus', _('PushPlus'));
		o.depends('notify_enable', '1');

		o = s.taboption('notify', form.Value, 'notify_telegram_bot_chat_id', _('Chat ID'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'notify_telegram_bot_token', _('Token'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'notify_telegram_bot_proxy', _('http proxy'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'notify_pushplus_token', _('Token'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('notify_channel', 'pushplus');

		// link
		o = s.taboption('link', form.Flag, 'link_enable', _('Enable another service\'s config'));
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

		// link_cloudflare
		o = s.taboption('link', form.Value, 'link_cloudflare_email', _('Email'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'link_cloudflare_api_key', _('API Key'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'link_cloudflare_zone_id', _('Zone ID'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'link_cloudflare_rule_name', _('Rule Name'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_origin_rule');
		o.depends('link_mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'link_cloudflare_rule_target_url', _('Target URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'cloudflare_redirect_rule');

		// link_emby
		o = s.taboption('link', form.Value, 'link_emby_url', _('EMBY URL'), _('such as http://127.0.0.1:8080 or http://ikuai.lan:8080.if use host,must close Rebind protection in DHCP and DNS'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		o = s.taboption('link', form.Value, 'link_emby_api_key', _('API Key'));
		o.datatype = 'host';
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		o = s.taboption('link', form.Flag, 'link_emby_use_https', _('Update HTTPS Port'), _('Set to False if you want to use HTTP'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		o = s.taboption('link', form.Flag, 'link_emby_update_host_with_ip', _('Update host with IP'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'emby');

		// link_qbittorrent
		o = s.taboption('link', form.Value, 'link_qb_web_url', _('Web UI URL'), _('such as http://127.0.0.1:8080 or http://ikuai.lan:8080.if use host,must close Rebind protection in DHCP and DNS'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'link_qb_username', _('Username'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'link_qb_password', _('Password'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Flag, 'link_qb_allow_ipv6', _('Allow IPv6'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'link_qb_ipv6_address', _('IPv6 Address'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_qb_allow_ipv6', '1');

		o = s.taboption('link', form.Flag, 'link_qb_advanced_enable', _('Qbittorrent Advanced Settings'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'link_qb_max_retries', _('Max Retries'), _('max retries,default 0 means execute only once'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_qb_advanced_enable', '1');

		o = s.taboption('link', form.Value, 'link_qb_sleep_time', _('Sleep Time'), _('Single sleep time, unit is seconds, default 0 is 3 seconds'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_qb_advanced_enable', '1');



		// link_transmission
		o = s.taboption('link', form.Value, 'link_tr_rpc_url', _('RPC URL'), _('such as http://127.0.0.1:8080 or http://ikuai.lan:8080.if use host,must close Rebind protection in DHCP and DNS'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Value, 'link_tr_username', _('Username'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Value, 'link_tr_password', _('Password'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Flag, 'link_tr_allow_ipv6', _('Allow IPv6'));
		o.modalonly = true;
		o.default = false;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Value, 'link_tr_ipv6_address', _('IPv6 Address'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_tr_allow_ipv6', '1');

		o = s.taboption('link', form.Flag, 'link_tr_advanced_enable', _('Transmission Advanced Settings'));
		o.default = false;
		o.modalonly = true;
		o.depends('link_mode', 'transmission');

		o = s.taboption('link', form.Value, 'link_tr_max_retries', _('Max Retries'), _('max retries,default 0 means execute only once'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_tr_advanced_enable', '1');

		o = s.taboption('link', form.Value, 'link_tr_sleep_time', _('Sleep Time'), _('Single sleep time, unit is seconds, default 0 is 3 seconds'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('link_tr_advanced_enable', '1');

		// Custom Settings
		o = s.taboption('custom', form.Flag, 'custom_enable', _('Enable custom script\'s config'));
		o.modalonly = true;
		o.ucioption = 'custom_script';
		o.load = function (section_id) {
			return this.super('load', section_id) ? '1' : '0';
		};
		o.write = function (section_id, formvalue) { };

		o = s.taboption('custom', form.Value, 'custom_script', _('custom script'));
		o.datatype = 'file';
		o.modalonly = true;
		o.depends('custom_enable', '1');

		// status
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

		return m.render();
	}
});
