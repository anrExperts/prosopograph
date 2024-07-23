xquery version "3.0";
module namespace bio.bio = "bio.bio";
(:~
 : This xquery module is derived from the xpr application
 :
 : @author emchateau & sardinecan (ANR Experts)
 : @since 2019-01
 : @licence GNU http://www.gnu.org/licenses
 : @version 0.2
 :
 : biographiX is free software: you can redistribute it and/or modify
 : it under the terms of the GNU General Public License as published by
 : the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 :)

import module namespace G = 'bio.globals' at './globals.xqm' ;
import module namespace bio.mappings.html = 'bio.mappings.html' at './mappings.html.xqm' ;
import module namespace bio.models.bio = 'bio.models.bio' at './models.bio.xqm' ;
import module namespace bio.models.statistics = 'bio.models.statistics' at './models.statistics.xqm' ;

import module namespace Session = 'http://basex.org/modules/session';
import module namespace functx = "http://www.functx.com";

declare namespace rest = "http://exquery.org/ns/restxq" ;
declare namespace file = "http://expath.org/ns/file" ;
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization" ;
declare namespace db = "http://basex.org/modules/db" ;
declare namespace web = "http://basex.org/modules/web" ;
declare namespace update = "http://basex.org/modules/update" ;
declare namespace perm = "http://basex.org/modules/perm" ;
declare namespace user = "http://basex.org/modules/user" ;
declare namespace session = 'http://basex.org/modules/session' ;
declare namespace http = "http://expath.org/ns/http-client" ;
declare namespace json = "http://basex.org/modules/json" ;

declare namespace ev = "http://www.w3.org/2001/xml-events" ;
declare namespace eac = "https://archivists.org/ns/eac/v2" ;
declare namespace rico = "rico" ;

declare namespace map = "http://www.w3.org/2005/xpath-functions/map" ;
declare namespace xf = "http://www.w3.org/2002/xforms" ;
declare namespace xlink = "http://www.w3.org/1999/xlink" ;

declare namespace bio = "bio" ;
declare default element namespace "bio" ;
declare default function namespace "bio.bio" ;

declare default collation "http://basex.org/collation?lang=fr" ;

(:~
 : This resource function defines the application root
 : @return redirect to the home page or to the install
 :)
declare 
  %rest:path("/bio")
  %output:method("xml")
function index() {
  if ( db:exists("bio") )
    then web:redirect("/bio/home") 
    else web:redirect("/bio/install") 
};

(:~
 : This resource function install
 : @return create the db
 : @todo create the prosopo db
 :)
declare 
  %rest:path("/bio/install")
  %output:method("xml")
  %updating
function install() {
  if (db:exists("bio")) 
    then (
      update:output("La base bio existe déjà !")
     )
    else (
      update:output("La base bio a été créée"),
      db:create( "bio")
      )
};


(:~
 : This resource function defines the application home
 : @return redirect to the expertises list
 :)
declare 
  %rest:path("/bio/home")
  %output:method("xml")
function home() {
  web:redirect("/bio/biographies/view")
};

(:~
 : This resource function creates the about page
 : @return an about page
 :)
declare
  %rest:path("/bio/about")
  %output:method("html")
function about() {
  let $content := map {
      'title' : 'À propos',
      'data' :
        <div>Application Bio</div>
    }
    let $outputParam := map {
      'layout' : "template.xml"
    }
    return bio.models.bio:wrapper($content, $outputParam)
};

(:~
 : This resource shows app weather
 : @todo template
 :)
declare
  %rest:path("bio/meteo")
  %output:method("html")
function meteo() {
  let $biographies := getBiographies()
  return
    <html>
      <head>
        <title>!bio¡</title>
        <meta charset="UTF-8"/>
      </head>
      <body>
        <div>
          <h1>Météo des experts</h1>
          <div class="prosopographie">
            <h2>Prosopographie</h2>
            <ul>
              <li>{fn:count($biographies/eac:eac-cpf) || ' fiches prosopographiques enregistrées dans la base de données'}
                <ul>{
                  for $entityType in fn:distinct-values($biographies/descendant::eac:identity/@localType)
                  return <li>{ fn:count($biographies/eac:eac[descendant::eac:identity[@localType = $entityType]]) || ' entités ayant pour qualité "' ||$entityType || '"' }</li>
                }</ul>
              </li>
              <li>{ fn:count($biographies/eac:eac[descendant::eac:localControl[@localType='detailLevel']/eac:term[fn:normalize-space(.) = 'completed']]) || ' fiches complètes' }</li>
              <li>{ fn:count($biographies/eac:eac[descendant::eac:localControl[@localType='detailLevel']/eac:term[fn:normalize-space(.) = 'in progress']]) || ' fiches en cours de dépouillement' }</li>
              <li>{ fn:count($biographies/eac:eac[descendant::eac:localControl[@localType='detailLevel']/eac:term[fn:normalize-space(.) = 'to revise']]) || ' fiches à revoir' }</li>
            </ul>
          </div>
        </div>
      </body>
    </html>
};

(:~
 : this function defines a static files directory for the app
 : @param $file file or unknown path
 : @return binary file
 :)
declare
  %rest:path('bio/files/{$file=.+}')
function bio.bio:file($file as xs:string) as item()+ {
  let $path := file:base-dir() || 'files/' || $file
  return
    (
      web:response-header( map {'media-type' : web:content-type($path)}),
      file:read-binary($path)
    )
};

(:~
 : This resource function lists the entities
 : @return an xml list of persons/corporate bodies
 :)
declare 
  %rest:path("/bio/biographies")
  %rest:produces('application/xml')
  %output:method("xml")
function getBiographies() {
  <bio>{ db:get('bio', 'biographies') }</bio>
};

(:~
 : This resource function creates an new entity
 : @return an xforms for the entity
:)
declare
  %rest:path("bio/biographies/new")
  %output:method("xml")
  %perm:allow("prosopography")
function newBiography() {
  let $content := map {
    'instance' : '',
    'model' : ('eacModel.xml', 'eacNoValidationModel.xml'),
    'trigger' : 'eacTrigger.xml',
    'form' : 'eacForm.xml'
  }
  let $outputParam := map {
    'layout' : "template.xml"
  }
  return(
    processing-instruction xml-stylesheet { fn:concat("href='", $G:xsltFormsPath, "'"), "type='text/xsl'"},
    <?css-conversion no?>,
    bio.models.bio:wrapper($content, $outputParam)
  )
};

(:~
 : This function consumes new entity
 : @param $param content
 :)
declare
  %rest:path("bio/biographies/put")
  %output:method("xml")
  %rest:header-param("Referer", "{$referer}", "none")
  %rest:PUT("{$param}")
  %perm:allow("prosopography")
  %updating
function putBiography($param, $referer) {
  let $db := db:get("bio")
  return
    if ($param/*/@xml:id) then
      let $location := fn:analyze-string($referer, 'bio/biographies/(.+?)/modify')//fn:group[@nr='1']
      return db:put('bio', $param, 'biographies/'|| $location ||'.xml')
    else
      let $type := switch ($param//eac:identity/eac:entityType/@value)
        case 'person' return 'person'
        case 'org' return 'org'
        case 'family' return 'family'
        default return 'other'
      let $id := $type || fn:generate-id($param)
      let $param :=
        copy $d := $param
        modify(
          insert node attribute xml:id {$id} into $d/*,
          replace value of node $d//eac:recordId with $id
        )
        return $d
      return(
        db:add('bio', $param, 'biographies/'|| $id ||'.xml'),
        update:output((
          <rest:response>
            <http:response status="200" message="">
              <http:header name="Content-Language" value="fr"/>
              <http:header name="Content-Type" value="text/plain; charset=utf-8"/>
            </http:response>
          </rest:response>,
          <result>
            <id>{$id}</id>
            <message>Une nouvelle entité a été ajoutée : {$param//eac:nameEntry[@preferred='true']/eac:part}.</message>
          </result>
        ))
      )
};

(:~
 : This resource function lists all the entities
 : @return an ordered list of expertises in html
 :)
declare
  %rest:path("bio/biographies/view")
  %rest:produces('application/html')
  %output:method("html")
  %output:html-version('5.0')
function getBiographiesHtml() {
 let $content := map {
    'title' : 'Liste des entités',
    'data' : getBiographies()
  }
  let $outputParam := map {
    'layout' : "listeBiographies.xml",
    'mapping' : bio.mappings.html:listEac2html(map:get($content, 'data'), map{})
  }
  return bio.models.bio:wrapper($content, $outputParam)
};

(:~
 : This resource function lists all the entities
 : @return an ordered list of entities in json
 :)
declare
  %rest:path("/bio/biographies/json")
  %rest:POST("{$body}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getBiographiesJson($body) {
  let $body := json:parse( $body, map{"format" : "xquery"})
  let $biographies := getBiographies()

  let $meta := map {
    'start' : $body?start,
    'count' : $body?count,
    'totalBiographies' : fn:count($biographies/eac:eac)
  }
  let $content := array{
    for $biography in fn:subsequence($biographies/eac:eac, $body?start, $body?count)
    return map{
      'id' : fn:normalize-space($biography/@xml:id),
      'name' : bio.mappings.html:getEntityName($biography/@xml:id)
    }
  }
  return map{
    "meta": $meta,
    "content": $content
  }
};

(:~
 : This resource function get an entity
 : @return an xml representation of an entity
 :)
declare
  %rest:path("bio/biographies/{$id}")
  %output:method("xml")
function getBiography($id) {
  db:get('bio', 'biographies/'||$id||'.xml')
};

(:~
 : This resource function modify an entity
 : @return an xforms to modify an entity
 :)
declare
  %rest:path("bio/biographies/{$id}/modify")
  %output:method("xml")
  %perm:allow("prosopography")
function modifyBiography($id) {
  let $content := map {
    'instance' : $id,
    'path' : 'biographies',
    'model' : ('eacModel.xml', 'eacNoValidationModel.xml'),
    'trigger' : 'eacTrigger.xml',
    'form' : 'eacForm.xml'
  }
  let $outputParam := map {
    'layout' : "template.xml"
  }
  return
    (processing-instruction xml-stylesheet { fn:concat("href='", $G:xsltFormsPath, "'"), "type='text/xsl'"},
    <?css-conversion no?>,
    bio.models.bio:wrapper($content, $outputParam)
    )
};

(:~
 : This resource function show an entity
 : @return an html view of an entity with xquery templating
 :)
declare
  %rest:path("/bio/biographies/{$id}/view")
  %rest:produces('application/html')
  %output:method("html")
  %output:html-version('5.0')
function getBiographyHtml($id) {
  let $content := map {
    'title' : 'Fiche de ' || $id,
    'id' : $id,
    'data' : getBiography($id)/eac:eac,
    'trigger' : '',
    'form' : ''
  }
  let $outputParam := map {
    'layout' : "ficheEntite.xml",
    'mapping' : bio.mappings.html:eac2html(map:get($content, 'data'), map{})
  }
  return bio.models.bio:wrapper($content, $outputParam)
};

(:~
 : This resource function lists an entities
 : @return an ordered list of entities in json
 :)
declare
  %rest:path("/bio/biographies/{$id}/json")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getBiographyJson($id) {
  let $biography := bio.bio:getBiography($id)
  let $meta := map {}
  let $content := map{
    'id' : fn:normalize-space($biography/eac:eac/eac:control/eac:recordId),
    'authorizedForm' : bio.mappings.html:getEntityName(fn:normalize-space($biography/eac:eac/@xml:id)),
    'alternativeForms' : if($biography/eac:eac/eac:cpfDescription/eac:identity/eac:nameEntry[@preferredForm != 'true'][fn:normalize-space(.)!='']) then array{
      for $alternativeForm in $biography/eac:eac/eac:cpfDescription/eac:identity/eac:nameEntry[@preferredForm != 'true'][fn:normalize-space(.)!='']
      return
      map:merge((
          map{'sources' : array{bio.mappings.html:getSources($alternativeForm/@sourceReference, $biography/eac:eac/eac:control/eac:sources, map{})}},
          map{'parts' : array{
            for $part in $alternativeForm/eac:part
            let $d := bio.mappings.html:getPart($part, map{})
            return
              map{'key' : $d[1], 'part': $d[2]}
          }}
      ))
    },
    'existDates' : bio.mappings.html:getEacDates($biography/eac:eac/eac:cpfDescription/eac:description/eac:existDates/eac:dateRange, $biography/eac:eac/eac:control/eac:sources, map{}),
    'sex' : $biography/eac:eac/eac:cpfDescription/eac:description/eac:localDescriptions/eac:localDescription[@localType='sex']/eac:term => fn:normalize-space(),
    (:'places' : if($biography/eac:cpfDescription/eac:description/eac:places/eac:place[fn:normalize-space(.)!='']) then array{
      for $place in $biography/eac:cpfDescription/eac:description/eac:places/eac:place[fn:normalize-space(.)!='']
      return map{
        'placeRole' : $place/eac:placeRole => fn:normalize-space(),
        'placeEntry' : $place/eac:placeEntry => fn:normalize-space(),
        'dates' : if($place/eac:dateSet/*[descendant-or-self::*/@standardDate != '' or descendant-or-self::*/@notAfter != '' or descendant-or-self::*/@notBefore != '']) then array{
          for $date in $place/eac:dateSet/*[descendant-or-self::*/@standardDate != '' or descendant-or-self::*/@notAfter != '' or descendant-or-self::*/@notBefore != '']
          return if($date/self::eac:dateRange) then map{
            'from' : map{
              'precision' : $date/eac:fromDate/@*[fn:local-name = ('standardDate', 'notBefore', 'notAfter')]/fn:local-name(),
              'date' : $date/eac:fromDate/@*[fn:local-name = ('standardDate', 'notBefore', 'notAfter')] => fn:normalize-space()
            },
            'to' : map{
              'precision' : $date/eac:toDate/@*[fn:local-name = ('standardDate', 'notBefore', 'notAfter')]/fn:local-name(),
              'date' : $date/eac:toDate/@*[fn:local-name = ('standardDate', 'notBefore', 'notAfter')] => fn:normalize-space()
            }
          } else map{
            'precision' : $date/@*[fn:local-name = ('standardDate', 'notBefore', 'notAfter')]/fn:local-name(),
            'date' : $date/@*[fn:normalize-space(.)!=''] => fn:normalize-space(),
            'sources' : if($date/bio:source[@xlink:href!='']) then array{
              for $source in $date/bio:source[@xlink:href!='']
              return map{
                'id' : $source/@xlink:href => fn:substring-after('#'),
                'source' : bio.mappings.html:getSource($source, map{}),
                'note' : $source => fn:normalize-space()
              }
            }
          }
        },
        'note' : $place/eac:descriptiveNote/eac:p => fn:normalize-space()
      }
    },:)
    'occupations' : if($biography/eac:eac/eac:cpfDescription/eac:description/eac:occupations/eac:occupation[fn:normalize-space(.)!='']) then array{
      for $occupation in $biography/eac:eac/eac:cpfDescription/eac:description/eac:occupations/eac:occupation[fn:normalize-space(.)!='']
      return map{
        'occupation' : $occupation/eac:term => fn:normalize-space(),
        'dates' : if($occupation/*[self::eac:date or self::eac:dateRange or self::eac:dateSet][.//@*[fn:normalize-space(.) castable as xs:date or xs:gYearMonth or xs:gYear]]) then array { bio.mappings.html:getEacDates($occupation/*[self::eac:date or self::eac:dateRange], $biography/eac:eac/eac:control/eac:sources, map{})},
        'sources' : if(fn:normalize-space($occupation/@sourceReference) != '') then bio.mappings.html:getEacSourceReference($occupation/@sourceReference, $biography/eac:eac/eac:control/eac:sources)
      }
    },
    'functions' : if($biography/eac:eac/eac:cpfDescription/eac:description/eac:functions/eac:function[fn:normalize-space(.)!='']) then array{
      for $function in $biography/eac:eac/eac:cpfDescription/eac:description/eac:functions/eac:function[fn:normalize-space(.)!='']
      return map{
        'function' : $function/eac:term => fn:normalize-space(),
        'dates' : if($function/*[self::eac:date or self::eac:dateRange or self::eac:dateSet][.//@*[fn:normalize-space(.) castable as xs:date or xs:gYearMonth or xs:gYear]]) then bio.mappings.html:getEacDates($function/*[self::eac:date or self::eac:dateRange], $biography/eac:eac/eac:control/eac:sources, map{}),
        'sources' : if(fn:normalize-space($function/@sourceReference) != '') then bio.mappings.html:getEacSourceReference($function/@sourceReference, $biography/eac:eac/eac:control/eac:sources)
      }
    },
    'events' : if($biography/eac:eac/eac:cpfDescription/eac:description/eac:biogHist/eac:chronList/eac:chronItem[fn:normalize-space(.)!='']) then array{
      for $event in $biography/eac:eac/eac:cpfDescription/eac:description/eac:biogHist/eac:chronList/eac:chronItem[fn:normalize-space(.)!='']
      return map{
        'event' : $event/eac:event => fn:normalize-space(),
        'place' : if($event/eac:place[fn:normalize-space(.)!='']) then $event/eac:place => fn:normalize-space(),
        (:@todo participants ?:)
        'sources' : if(fn:normalize-space($event/@sourceReference) != '') then bio.mappings.html:getEacSourceReference($event/@sourceReference, $biography/eac:eac/eac:control/eac:sources),
        'dates' : if($event/*[self::eac:date or self::eac:dateRange or self::eac:dateSet][.//@*[fn:normalize-space(.) castable as xs:date or xs:gYearMonth or xs:gYear]]) then bio.mappings.html:getEacDates($event/*[self::eac:date or self::eac:dateRange or self::eac:dateSet], $biography/eac:eac/eac:control/eac:sources, map{})
      }
    },
    'relations' : if(fn:count($biography/eac:eac/eac:cpfDescription/eac:relations/eac:relation[fn:normalize-space(.)!='']) > 0) then array{
      for $relation in $biography/eac:eac/eac:cpfDescription/eac:relations/eac:relation[fn:normalize-space(.)!=''] return map{
        'relation' : $relation/eac:targetEntity/eac:part[@localType='full'] => fn:normalize-space(),
        'roles' : if($relation/eac:targetRole[fn:normalize-space(.)!='']) then array{
          for $role in $relation/eac:targetRole
          let $sources := $relation/eac:relationType[@id = fn:substring-after($role/@target, '#')]/@sourceReference
          return map{
            'role' : $role => fn:normalize-space(),
            'sources' : if(fn:normalize-space($sources) != '') then bio.mappings.html:getEacSourceReference($sources, $biography/eac:eac/eac:control/eac:sources)
          }
        },
        'events' : if($relation/@target[fn:normalize-space(.)!='']) then array{
          for $event in fn:tokenize($relation/@target, ' ')
          let $eventId := fn:substring-after($event, '#')
          return map{
            'event' : $biography//eac:chronItem[@id = $eventId]/eac:event => fn:normalize-space()
          }
        }
      }
    }
  }
  return map {
    'meta' : $meta,
    'content' : $content
  }
};

(:~
 : This resource function lists the persons or corporate bodies
 : @return an xml list of persons/corporate bodies
 :)
declare
  %rest:path("/bio/search/{$person}")
  %rest:produces('application/xml')
  %output:method("xml")
function getPerson($person) {
  let $prosopo := getBiographies()/eac:eac
  return (
    <results xmlns="">{
      for $person in $prosopo[fn:normalize-space(eac:cpfDescription/eac:identity) contains text { $person } all words using fuzzy]
      return <result xml:id="{ $person/@xml:id }">{$person/descendant::eac:nameEntry[@preferredForm='true'][@status='authorized'][1]/eac:part[@localType='full'] => fn:normalize-space()}</result>
    }</results>
  )
};

(:~
 : This function consumes
 :
 :)
declare
  %rest:path("bio/networks")
  %output:method("json")
  %rest:produces("application/json")
function getNetworks() {
  let $nodes :=
    for $entity in db:get('bio', 'biographies')
    let $id := $entity/eac:eac/@xml:id => fn:normalize-space()
    return map {
      "id" : $id,
      "name" : bio.mappings.html:getEntityName($id)
    }

  let $links :=
    for $relation in db:get('bio', 'biographies')/descendant::eac:relation[descendant::eac:part[@localType="databaseRef"][fn:normalize-space(.)!='']]
    let $sourceId := $relation/ancestor::eac:eac/@xml:id => fn:normalize-space()
    let $targetId := $relation/descendant::eac:part[@localType="databaseRef"]/fn:substring-after(., '#') => fn:normalize-space()
    return map {
      'source' : $sourceId,
      'target' : $targetId
    }

  return map {
    'nodes' : array{$nodes},
    'links' : array{$links}
  }
};

(:~
 : This function consumes
 :
 :)
declare
  %rest:path("bio/networks/{$id}")
  %output:method("json")
  %rest:produces("application/json")
function getEntityNetworks($id) {
  let $entity := db:get('bio', 'biographies')/eac:eac[@xml:id=$id]
  let $relations := $entity/descendant::eac:relation[descendant::eac:part[@localType="databaseRef"][fn:normalize-space(.)!='']]

  let $nodes := (
    map {
      "id" : $id,
      "name": bio.mappings.html:getEntityName($id)
    },
    for $relation in $relations
    let $entityId := $relation/descendant::eac:part[@localType="databaseRef"]/fn:substring-after(., '#') => fn:normalize-space()
    return map {
    "id" : $entityId,
    "name" : bio.mappings.html:getEntityName($entityId)
    }
  )

  let $links :=
    for $relation in $relations
    let $sourceId := $id
    let $targetId := $relation/descendant::eac:part[@localType="databaseRef"]/fn:substring-after(., '#') => fn:normalize-space()
    return map {
      'source' : $sourceId,
      'target' : $targetId
    }

  return map {
    'nodes' : array{$nodes},
    'links' : array{$links}
  }
};

(:~
 : This resource function displays network
 : @return
 :)
declare
  %rest:path("/bio/networks/view")
  %rest:produces('application/xml')
  %output:method("html")
function showNetwork() {
let $content := map {
      'title' : 'Networks',
      'data' : ''
    }
    let $outputParam := map {
      'layout' : "network.xml"
    }
    return bio.models.bio:wrapper($content, $outputParam)
};


(:~
 : Permissions: biographies
 : Checks if the current user is granted; if not, redirects to the login page.
 : @param $perm map with permission data
 :)
(: declare
    %perm:check('bio/biographies', '{$perm}')
function permBiographies($perm) {
  let $user := Session:get('id')
  return
    if((fn:empty($user) or fn:not(user:list-details($user)/*:info/*:grant/@type = $perm?allow)) and fn:ends-with($perm?path, 'new'))
      then web:redirect('/bio/login')
    else if((fn:empty($user) or fn:not(user:list-details($user)/*:info/*:grant/@type = $perm?allow)) and fn:ends-with($perm?path, 'modify'))
      then web:redirect('/bio/login')
    else if((fn:empty($user) or fn:not(user:list-details($user)/*:info/*:grant/@type = $perm?allow)) and fn:ends-with($perm?path, 'put'))
      then web:redirect('/bio/login')
}; :)

(:~ Login page (visible to everyone). :)
declare
  %rest:path("bio/login")
  %output:method("html")
function login() {
  <html>
    Please log in:
    <form action="/bio/login/check" method="post">
      <input name="name"/>
      <input type="password" name="pass"/>
      <input type="submit"/>
    </form>
  </html>
};

(:
 : this function checks if the user is registered
 :)
declare
  %rest:path("bio/login/check")
  %rest:query-param("name", "{$name}")
  %rest:query-param("pass", "{$pass}")
function login($name, $pass) {
  try {
    user:check($name, $pass),
    Session:set('id', $name),
    web:redirect("/")
  } catch user:* {
    web:redirect("/")
  }
};

(:
 : this function logs out current user
 :)
declare
  %rest:path("bio/logout")
function logout() {
  Session:delete('id'),
  web:redirect("/")
};

(:~
 : This resource function edits a new user
    : @return an xforms to edit a new user
:)
declare
  %rest:path("bio/users/new")
  %output:method("xml")
  %perm:allow("admin", "write")
function newUser() {
  let $content := map {
    'instance' : '',
    'model' : 'bioUserModel.xml',
    'trigger' : '',
    'form' : 'bioUserForm.xml'
  }
  let $outputParam := map {
    'layout' : "template.xml"
  }
  return
    (processing-instruction xml-stylesheet { fn:concat("href='", $G:xsltFormsPath, "'"), "type='text/xsl'"},
    <?css-conversion no?>,
    bio.models.bio:wrapper($content, $outputParam)
    )
};

(:~
 : This function creates new user in dba.
 : @todo return creation message
 : @todo control for duplicate user.
 :)
declare
  %rest:path("bio/users/put")
  %output:method("xml")
  %rest:header-param("Referer", "{$referer}", "none")
  %rest:PUT("{$param}")
  %perm:allow("admin", "write")
  %updating
function putUser($param, $referer) {
  let $user := $param
  let $userName := fn:normalize-space($user/*:user/*:name)
  let $userPwd := fn:normalize-space($user/*:user/*:password)
  let $userPermission := fn:normalize-space($user/*:user/*:permission)
  let $userInfo :=
    <info xmlns="">{
        for $right in $user/*:user/*:info/*:grant
        return <grant type="{$right/@type}">{fn:normalize-space($right)}</grant>
    }</info>
  return
    user:create(
      $userName,
      $userPwd,
      $userPermission,
      'bio',
      $userInfo)
};
