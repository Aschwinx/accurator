/*******************************************************************************
Accurator Domain
This code loads domain options into the page, where the options depend on the
domains loaded in the triple store.
*******************************************************************************/
var locale, domain, experiment, ui;

function domainInit() {
	locale = getLocale();
	// Be domain agnostic on domain selection screen
	domain = "generic";
	experiment = getExperiment();

	// Add language switch to navbar
	populateFlags(locale);

	onLoggedIn = function(loginData) {
		setLinkLogo("profile");
		onDomains = function(data){
			populateDomains(data);

			// Get generic domain settings before populating ui
			onDomain = function(domainSettings) {
				ui = getUI(domainSettings, "domain");
				populateUI();
				var userName = getUserName(loginData.user);
				populateNavbar(userName, [{link:"profile.html", name:"Profile"}]);
			};
			domainSettings(domain, onDomain);
		};
		// Get a list of the available domain (utilities function)
		getAvailableDomains(onDomains);
	};
	// If user is not logged go to intro page
	onDismissal = function(){document.location.href="intro.html";};
	logUserIn(onLoggedIn, onDismissal);
}

function nextPage() {
	return function(){document.location.href="expertise.html"};
}

function populateUI() {
	$.getJSON("ui_elements", {locale:locale, ui:ui, type:"labels"})
		.done(function(labels){
			document.title = labels.domainPageTitle;
			$("#domainTxtTitle").append(labels.domainTxtTitle);
		});
}

function populateDomains(domainLabels) {
	var row;

	// Get domain settings for all the domains
	for(var i=0; i<domainLabels.length; i++) {
		if(!(i%2===0)) {
			row = parseInt((i/2) + 0.5);
			// Add a new row for every two domains
			$(".domainDiv").append(
				$.el.div({'class':'row',
						  'id':'domain' + row}));
		}

		// Add domain specific html to rows
		$.getJSON("domains", {domain:domainLabels[i]})
			.done(function(data){
				if(!(data.domain === "generic")) {
					domainHtml(data, row);
				}
			});
	}
}

function domainHtml(domainData, row) {
	var domain = domainData.domain;
	$.getJSON("ui_elements",
			  {locale:locale,
			   ui:domainData.ui + "domain",
			   type:"labels"})
		.done(function(data){
			$("#domain" + row).append(
				$.el.div({'class':'noPadding col-md-6'},
					$.el.h3({'class':'domainTitle',
							 'id':'text' + domain},
							 data.domainLabel),
					$.el.img({'class':'domainImage',
							  'id':'image' + domain,
							  'src':domainData.image})));
			if(domainData.image_brightness === "dark")
				$("#text" + domainData.domain).css('color', '#fff');
			addDomainEvent(domain);
		});
}

function addDomainEvent(domain) {
	$("#image"+domain).click(function() {
		setDomain(domain, nextPage());
	});
	$("#text"+domain).click(function() {
		setDomain(domain, nextPage());
	});
}
