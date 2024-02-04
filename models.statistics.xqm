xquery version "3.0";
module namespace bio.models.statistics = "bio.models.statistics";
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

import module namespace G = 'bio.globals' at './globals.xqm' ;
import module namespace bio.bio = "bio.bio" at './bio.xqm' ;
import module namespace bio.mappings.html = 'bio.mappings.html' at './mappings.html.xqm' ;

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

declare namespace bio = "bio" ;
declare namespace ev = "http://www.w3.org/2001/xml-events" ;
declare namespace eac = "https://archivists.org/ns/eac/v2" ;
declare namespace rico = "rico" ;

declare namespace map = "http://www.w3.org/2005/xpath-functions/map" ;
declare namespace xf = "http://www.w3.org/2002/xforms" ;
declare namespace xlink = "http://www.w3.org/1999/xlink" ;

declare default element namespace "bio" ;
declare default function namespace "bio.models.statistics" ;

declare default collation "http://basex.org/collation?lang=fr" ;


declare function getDistribution($seq, $step, $max) {
  for $n in 1 to $max
  let $multiplier := $step
  let $step := $n * $multiplier
  return (
    if($n = 20) then map{
        $step : fn:count($seq[fn:number(.) >= $step])
    }
    else if ($n = 1) then map {
      $step : fn:count($seq[fn:number(.) <= $step and fn:number(.) >= $step - $multiplier])
    }
    else map{
      $step : fn:count($seq[fn:number(.) <= $step and fn:number(.) > $step - $multiplier])
    }
  )
};