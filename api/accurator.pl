:- module(accurator, []).

/** <module> Accurator
*/

:- use_module(library(semweb/rdf_db)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_server_files)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).

http:location(html, cliopatria(html), []).
http:location(img, cliopatria(img), []).
user:file_search_path(html, web(html)).
user:file_search_path(img, web(img)).

:- http_handler(cliopatria('.'), serve_files_in_directory(html), [prefix]).
:- http_handler(img('.'), serve_files_in_directory(img), [prefix]).
:- http_handler(cliopatria(ui_elements), ui_elements_api,  []).

:- rdf_register_prefix(aui, 'http://semanticweb.cs.vu.nl/accurator/ui/').
:- rdf_register_prefix(abui, 'http://semanticweb.cs.vu.nl/accurator/ui/bird#').
:- rdf_register_prefix(gn, 'http://www.geonames.org/ontology#').

%%	ui_elements_api(+Request)
%
%	Retrieves ui elements, according to the given locale, type and ui
%	screen. First it gets the url parameters, second it queries for the
%	results, after which the data is outputted
%	as json.
ui_elements_api(Request) :-
    get_parameters(Request, Options),
	option(type(Type), Options),
	get_elements(Type, Dic, Options),
	reply_json_dict(Dic).

%%	get_parameters(+Request, -Options)
%
%	Retrieves an option list of parameters from the url.
get_parameters(Request, Options) :-
    http_parameters(Request,
        [ui(UI,
			[description('The ui screen for which text elements are retrieved'),
			 optional(false)]),
		 locale(Locale,
				[description('Locale of language elements to retrieve'),
				 optional(false)]),
		 type(Type,
				[description('Type of elements to retrieve'),
				 optional(type)])
	]),
    Options = [ui(UI), locale(Locale), type(Type)].

get_elements(labels, Dic, Options) :-
	get_text_elements(Dic, Options).

get_elements(countries, Dic, Options) :-
	get_countries(Dic, Options).

get_countries(Dic, _Options) :-
	findall(GeonamesID-CountryName,
			(	rdf(GeonamesCountry, gn:featureClass, gn:'A'),
				%only english for now
				rdf(GeonamesCountry, gn:name, literal(lang(en, CountryName))),
				rdf(GeonamesCountry, gn:geonamesID, literal(GeonamesIDInt)),
				atomic_list_concat(['id-',GeonamesIDInt], GeonamesID)),
			CountryNames),
	dict_pairs(Dic, elements, CountryNames).

%%	get_text_elements(-TextDic, +Options)
%
%	Retrieves text elements according to the ui and locale specified in
%	Options.
get_text_elements(TextDic, Options) :-
	option(locale(Locale), Options),
	option(ui(UI), Options),
	findall(Label-Literal,
			(	rdf(UI, Predicate, literal(lang(Locale, Literal))),
				rdf(Predicate, rdf:type, aui:'UILabel'),
				iri_xml_namespace(Predicate, _, Label)),
			LabelList0),
	get_selector_options(UI, Locale, SelectorFields),
	append(LabelList0, SelectorFields, LabelList),
	dict_pairs(TextDic, elements, LabelList).

get_selector_options(UI, Locale, SelectorFields) :-
	findall(SelectorLabel-LiteralArray,
			(	rdf(UI, aui:hasSelector, Selector),
				rdf(Selector, rdf:type, aui:'SelectorField'),
				 iri_xml_namespace(Selector, _, SelectorLabel),
				get_selector_labels(Selector, Locale, LiteralArray)
				),
			SelectorFields).

get_selector_labels(Selector, Locale, LiteralDict) :-
	findall(OptionLabel-Literal,
			(	rdf(Selector, Predicate, literal(lang(Locale, Literal))),
				rdf(Predicate, rdf:type, aui:'UILabel'),
				iri_xml_namespace(Predicate, _, OptionLabel)),
			LiteralArray),
	dict_pairs(LiteralDict, elements, LiteralArray).
