
Utils = {
	formatDate: function(date, resolution_hours) {
		var hours = date.getHours();
		var minutes = date.getMinutes();
		var ampm = hours >= 12 ? 'pm' : 'am';
		hours = hours % 12;
		hours = hours ? hours : 12; // the hour '0' should be '12'
		minutes = minutes < 10 ? '0'+minutes : minutes;
		var strTime = hours + ':' + minutes + ' ' + ampm;
		var returnVal;

		if (resolution_hours < 24) {
			returnVal = strTime;
		}else {
			returnVal = date.getMonth()+1 + "/" + date.getDate() + " " + strTime;
		}
		return returnVal;
	},
	getParameterByName: function (name, url) {
		if (!url) url = window.location.href;
		name = name.replace(/[\[\]]/g, "\\$&");
		var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
			results = regex.exec(url);
		if (!results) return null;
		if (!results[2]) return '';
		return decodeURIComponent(results[2].replace(/\+/g, " "));
	},
	sumValues: function(array) {
		var total = 0;
		for(var i=0; i<array.length; i++) {
			if (array[i] !== null) {
				total += array[i];
			}
		}
		return total;
	},
	maxValue: function(array) {
		var max = 0;
		for(var i=0; i<array.length; i++) {
			if (array[i] > max) {
				max = array[i];
			}
		}
		return max;
	},
	getKeys: function(obj) {
		var keys = [], name;
		for (name in obj) {
			if (obj.hasOwnProperty(name)) {
					keys.push(name);
			}
		}
		return keys;
	},
	getCookie: function(cname) {
		var name = cname + "=";
		var ca = document.cookie.split(';');
		for (var i = 0; i < ca.length; i++) {
			var c = ca[i];
			while (c.charAt(0) == ' ') c = c.substring(1);
			if (c.indexOf(name) != -1) return c.substring(name.length, c.length);
		}
		return "";
	}
};

String.prototype.jsonizer = {
	replacer: function(match, pIndent, pKey, pVal, pEnd) {
		var key = '<span class=json-key>';
		var val = '<span class=json-value>';
		var str = '<span class=json-string>';
		var r = pIndent || '';
		if (pKey)
		 r = r + key + pKey.replace(/[": ]/g, '') + '</span>: ';
		if (pVal)
		 r = r + (pVal[0] == '"' ? str : val) + pVal + '</span>';
		return r + (pEnd || '');
		},
	prettyPrint: function(obj) {
		var jsonLine = /^( *)("[\w]+": )?("[^"]*"|[\w.+-]*)?([,[{])?$/mg;
		return JSON.stringify(obj, null, 3)
		 .replace(/&/g, '&amp;').replace(/\\"/g, '&quot;')
		 .replace(/</g, '&lt;').replace(/>/g, '&gt;')
		 .replace(jsonLine, String.prototype.jsonizer.replacer);
		}
};