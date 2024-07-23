xquery version "3.0";
module namespace bio.mappings.html = "bio.mappings.html";
(:~
 : This xquery module is an application for bio
 :
 : @author emchateau & sardinecan (ANR Experts)
 : @since 2019-01
 : @licence GNU http://www.gnu.org/licenses
 : @version 0.2
 :
 : bio is free software: you can redistribute it and/or modify
 : it under the terms of the GNU General Public License as published by
 : the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 :)

import module namespace bio.bio = "bio.bio" at './bio.xqm' ;
import module namespace G = 'bio.globals' at './globals.xqm' ;
import module namespace functx = "http://www.functx.com";
import module namespace Session = 'http://basex.org/modules/session';

declare namespace db = "http://basex.org/modules/db" ;
declare namespace file = "http://expath.org/ns/file" ;
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization" ;
declare namespace perm = "http://basex.org/modules/perm" ;
declare namespace web = "http://basex.org/modules/web" ;
declare namespace user = "http://basex.org/modules/user" ;

declare namespace ev = "http://www.w3.org/2001/xml-events" ;
declare namespace eac = "https://archivists.org/ns/eac/v2" ;
declare namespace rico = "rico" ;

declare namespace map = "http://www.w3.org/2005/xpath-functions/map" ;
declare namespace xf = "http://www.w3.org/2002/xforms" ;
declare namespace xlink = "http://www.w3.org/1999/xlink" ;

declare namespace bio = "bio" ;
declare default function namespace "bio.mappings.html" ;

declare default collation "http://basex.org/collation?lang=fr" ;


declare function getFormatedDate($node as node()*, $options as map(*)) as xs:string {
  (:@todo make it work with string and node:)
  switch ($node)
    case $node[(@when | @notAfter | @notBefore | @standardDate) castable as xs:date] return fn:format-date(xs:date($node/(@when | @notAfter | @notBefore | @standardDate)), '[D01] [Mn] [Y0001]', 'fr', (), ())
    case $node[(@when | @notAfter | @notBefore | @standardDate) castable as xs:gYearMonth] return fn:format-date(xs:date($node/(@when | @notAfter | @notBefore | @standardDate) || '-01'), '[Mn] [Y0001]', 'fr', (), ())
    case $node[(@when | @notAfter | @notBefore | @standardDate) castable as xs:gYear] return fn:format-date(xs:date($node/(@when | @notAfter | @notBefore | @standardDate) || '-01-01'), '[Y0001]', 'fr', (), ())
    case $node[(@when | @notAfter | @notBefore | @standardDate) = ''] return '..'
    default return $node/@when
};

(:~
 : This function dispatches the treatment of the eac XML document
 :)
declare
  %output:indent('no')
function eac2html($node as node()*, $options as map(*)) as item()* {
  <article>{
    getIdentity($node/eac:cpfDescription/eac:identity, $options),
    if($node/eac:cpfDescription/eac:description) then getDescription($node/eac:cpfDescription/eac:description, $options)
  }</article>
};

(:~
 : This function serialize a list of entities
 : @param
 :)
declare function listEac2html($node as node()*, $options as map(*)) as item()* {
  <ul id="list">{
    for $entity in $node//eac:eac
    let $id := $entity/@xml:id => fn:normalize-unicode()
    let $name := $entity//eac:nameEntry[@status='authorized'] => fn:normalize-unicode()
    let $dates := $entity/@xml:id => fn:normalize-unicode()
    return
      <li>
        <h3 class="name">{$name}</h3>
        <p class="date">{$dates}</p>
        <p><a class="view" href="{'/bio/biographies/' || $id || '/view'}">Voir</a> | <a class="modify" href="{'/bio/biographies/' || $id || '/modify'}">Modifier</a></p>
      </li>
  }</ul>
};

declare function serializebio($node as node()*, $options as map(*)) as item()* {
  typeswitch($node)
    case text() return $node[fn:normalize-unicode(.)!='']
    default return passthrubio($node, $options)
  };

(:~
 : This function pass through child nodes (xsl:apply-templates)
 :)
declare
  %output:indent('no')
function passthrubio($nodes as node(), $options as map(*)) as item()* {
  for $node in $nodes/node()
  return serializebio($node, $options)
};

(:~
 : This function pass through child nodes (xsl:apply-templates)
 :)
declare
  %output:indent('no')
function passthru($nodes as node(), $options as map(*)) as item()* {
  for $node in $nodes/node()
  return eac2html($node, $options)
};

declare function getIdentity($node as node()*, $options as map(*)) as node()* {
  <header>{(
    <h2>{ getEntityName($node/ancestor::eac:eac/eac:control/eac:recordId) }</h2>,
    <span class="id">{ getEntityId($node/ancestor::eac:eac/eac:control/eac:recordId, $options) }</span>,
    for $alternativeForm in $node/eac:nameEntry[@preferredForm!='true']
    return
      <div>
        <h4>Forme attestée du nom</h4>
        <ul>{
          for $part in $alternativeForm/eac:part
          return <li>{getPart($part, $options)[1] || ' : ' || getPart($part, $options)[2]}</li>
        }</ul>
        {if($alternativeForm/@sourceReference != '') then
        <ul>
          <lh>{if(fn:tokenize(fn:normalize-space($alternativeForm/@sourceReference))[2]) then 'Sources' else 'Source'}</lh>
          {for $source in getSources($alternativeForm/@sourceReference, $alternativeForm/ancestor::eac:eac/eac:control/eac:sources, $options)
          return
            <li>{$source}</li>}
        </ul>}
      </div>
  )}</header>
};

declare function getEntityName($id as xs:string*) as xs:string {
  let $prosopo := bio.bio:getBiographies()
  let $entityName := $prosopo/eac:eac[@xml:id=$id]/eac:cpfDescription/eac:identity/eac:nameEntry[@preferredForm='true' and @status='authorized'][1]/eac:part[@localType='full'] => fn:normalize-space()
  return $entityName
};

declare function getSources($refs as xs:string, $sources as node()*, $options as map(*)) as xs:string* {
let $refs := fn:tokenize($refs, ' ')
for $ref in $refs
return getSource($ref, $sources, $options)
};

declare function getSource($ref as xs:string, $node as node(), $options as map(*)) as xs:string {
let $source := $node/eac:source[@id = fn:substring-after($ref, '#')]/eac:reference => fn:normalize-space()
return $source
};

declare function getPart($node as node(), $options as map(*)) as xs:string+ {
  let $value := $node => fn:normalize-space()
  let $key := switch ($node/@localType => fn:normalize-space())
    case 'surname' return 'Nom'
    case 'forename' return 'Prénom'
    case 'particle' return 'Particule'
    case 'common' return 'Titre d’appel'
    case 'formal' return 'Titre institutionnel'
    case 'academic' return 'Titre académique'
    case 'religious' return 'Titre religieux'
    case 'nobiliary' return 'Titre nobiliaire'
    default return 'Partie du nom indéterminée'

  return ($key, $value)
};

declare function getEntityId($node as node(), $options as map(*)) as xs:string {
  let $id := $node => fn:normalize-space()
  return $id
};

declare function getDescription($node as node()*, $options as map(*)) as item()*{
  <div>
    <h4>Description</h4>
    <ul>{
      if($node/eac:existDates) then getExistDates($node/eac:existDates, $options),
      if(fn:normalize-space($node/eac:localDescriptions/eac:localDescription[@localType="sex"]) != '') then
      <li>{getSex($node/eac:localDescriptions/eac:localDescription[@localType="sex"], $options)}</li>
    }</ul>
  </div>,
  if($node/eac:functions) then getFunctions($node/eac:functions, $options),
  if($node/eac:functions) then getBiogHist($node/eac:biogHist, $options)
};

declare function getSex($node as node(), $options as map(*)) as xs:string {
  let $sex :=
    switch (fn:normalize-space($node))
    case 'male' return 'Homme'
    case 'female' return 'Femme'
    default return ()
  return $sex
  (: @todo restreindre l’appel au sex :)
};

declare function getFunctions($node as node(), $options as map(*)) as node(){
  <div class="function">
    <h4>Fonctions</h4>
    {for $function in $node/eac:function
    return getFunction($function, $options)}
  </div>
};

declare function getFunction($node as node(), $options as map(*)) as node() {
  <div>
    <p>{$node/eac:term}, de {if($node/eac:dateRange) then getDate($node/eac:dateRange, $options)}</p>
  </div>
  (: @todo prévoir cas où date fixe :)
};

declare function getBiogHist($node as node()*, $options as map(*)) as node()* {
  <div class="biogHist">
    <h4>Informations biographiques</h4>
    { if($node/eac:chronList) then getChronList($node/eac:chronList, $options) }
  </div>
};

declare function getChronList($node as node(), $options as map(*)) as node()* {
  for $chronItem in $node/eac:chronItem
  return
    <div>
      <h5>{$chronItem/eac:event => fn:normalize-space()}</h5>
      <p>Date : { if($chronItem/*[fn:local-name() = 'date' or fn:local-name() = 'dateRange']) then getDate($chronItem/*[fn:local-name() = 'date' or fn:local-name() = 'dateRange'], $options) }</p>
    </div>
};

declare function getExistDates($node as node(), $options as map(*)) as node() {
  <li>{ 'Dates d’existence : ' || getDate($node/*, $options)}</li>
};

declare function getDate($node as node(), $options as map(*)) as xs:string {
  switch($node)
  case $node[self::eac:dateRange] return
    fn:string-join(
      ($node/eac:fromDate, $node/eac:toDate) ! getPrecision(., $options),
      ' à '
    )
  case $node[self::eac:date[@*!='']] return getPrecision($node, $options)
  case $node[self::eac:dateSet] return (
    let $dateSet :=
      for $date in $node/* return getDate($date, $options)
    return fn:string-join($dateSet, ' ; ')
  )
  default return 'aucune date mentionnée'
  (: @todo mettre valeur vide en cas d’abs :)
};

declare function getPrecision($node as node(), $options as map(*)) as xs:string* {
  switch ($node)
  case $node[@notAfter] return (getFormatedDate($node, $options) || ' ]')
  case $node[@notBefore] return ('[ ' || getFormatedDate($node, $options))
  case $node[@standardDate] return (getFormatedDate($node, $options))
  default return '..'
};

declare function getEacDates($node as node(), $sources as node(), $option as map(*)) {
  switch($node)
  case $node[self::eac:dateRange] return getEacDateRange($node, $sources, map{})
  case $node[self::eac:dateSet] return getEacDateSet($node, $sources, map{})
  default return getEacDate($node, $sources, map{})
};

declare function getEacDate($node as node(), $sources as node(), $option as map(*)) as map(*) {
  map {
    'precision' : $node/@*[fn:local-name()='standardDate' or fn:local-name()='notBefore' or fn:local-name()='notAfter'][fn:normalize-space(.)!='']/fn:local-name(),
    'date' : $node/@*[fn:local-name()='standardDate' or fn:local-name()='notBefore' or fn:local-name()='notAfter'][fn:normalize-space(.)!=''] => fn:normalize-space(),
    'certainty' : $node/@certainty => fn:normalize-space(),
    'sources' : if($node[fn:normalize-space(@sourceReference)!='']) then getEacSourceReference($node/@sourceReference, $sources)
  }
};

declare function getEacDateRange($node as node(), $sources as node(), $option as map(*)) as map(*) {
  map {
    'from' : getEacDate($node/eac:fromDate, $sources, map{}),
    'to' : getEacDate($node/eac:toDate, $sources, map{})
  }
};

declare function getEacDateSet($node, $sources as node(), $option as map(*)) {
  array {
    for $date in $node/*
    return getEacDates($date, $sources, map{})
  }
};

declare function getEacSourceReference($node, $option) {
  if($node[fn:normalize-space(.)!='']) then array{
    for $source in fn:tokenize($node, ' ')
    return map {
      'source' : $option/eac:source[@id = $source => fn:substring-after('#')] => fn:normalize-space(),
      'id' : ''
    }
  }
};