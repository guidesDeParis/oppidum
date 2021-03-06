xquery version "1.0";
(: ------------------------------------------------------------------
   Oppidum framework sample controller

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Sample Oppidum controller. It just define a home page URL that shows
   Oppidum version, a scaffold page and the admin module. The admin module can
   then be used to update the Oppidum applications installed inside the DB.

   NOTE: gen:process() still serves Oppidum static resources. The convention is
   that these resources should be addressed with a URL ending in '/static/*'
   (usually generated in the site's epilogue). However we recommend not to use it
   and to use an Apache proxy or NGINX proxy configured to directly serve all
   '/oppidum/static/*' resources directly from the file system.

   COPY this file file to the '/db/www/root' collection if you want to use it

   February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

import module namespace xdb="http://exist-db.org/xquery/xmldb"; (: only for 'curtain' mode :)
import module namespace gen = "http://oppidoc.com/oppidum/generator" at "../oppidum/lib/pipeline.xqm";

(: ======================================================================
                  Site default access rights
   ====================================================================== :)
declare variable $access := <access>
  <rule action="POST" role="u:admin" message="database administrator"/>
</access>;

(: ======================================================================
                  Site default actions
   ====================================================================== :)
declare variable $actions := <actions error="models/error.xql">
  <action name="login" depth="0"> <!-- may be GET or POST -->
    <model src="oppidum:actions/login.xql"/>
    <view src="oppidum:views/login.xsl"/>
  </action>
  <action name="logout" depth="0">
    <model src="oppidum:actions/logout.xql"/>
  </action>
  <!-- NOTE: unplug this action from @supported on mapping's root node in production -->
  <action name="install" depth="0">
    <model src="oppidum:scripts/install.xql"/>
  </action>
</actions>;

(: ======================================================================
                  Site mappings
   ====================================================================== :)
declare variable $mapping := <site startref="home" supported="login logout install" db="/db/www/oppidum" confbase="/db/www/oppidum" key="oppidum" mode="test">
  <!-- <error mesh="standard"/> -->
  <item name="home">
    <model src="models/version.xql"/>
  </item>
  <!-- Oppidum administration module (backup / restore) -->
  <item name="admin" resource="none" method="POST">
    <access>
      <rule action="GET POST" role="u:admin" message="admin"/>
    </access>
    <model src="oppidum:modules/admin/restore.xql"/>
    <view src="oppidum:modules/admin/restore.xsl"/>
    <action name="POST">
      <model src="oppidum:modules/admin/restore.xql"/>
      <view src="oppidum:modules/admin/restore.xsl"/>
    </action>
  </item>
  <item name="scaffold" collection="monappli" resource="none">
    <model src="models/scaffold.xql"/>
    <view src="views/scaffold.xsl"/>
  </item>
  <collection name="test" supported="naction">
    <!-- <import module="test"/> -->
    <item name="generator" method="POST">
      <access>
        <rule action="POST" role="all"/>
      </access>
      <model src="oppidum:test/generator.xql"/>
      <action name="POST">
        <model src="oppidum:test/generator.xql"/>
      </action>
    </item>
    <item name="skin">
      <model src="oppidum:test/skin.xql"/>
    </item>
    <item name="inspect" supported="POST">
      <model src="oppidum:models/inspect.xql"/>
      <view/>
      <action name="POST">
        <model src="oppidum:models/inspect.xql"/>
      </action>
    </item>
  </collection>
</site>;

declare variable $curtain := (); 
(:declare variable $curtain := <site startref="home" supported="login" db="/db/www/oppidum" confbase="/db/www/oppidum" key="oppidum" mode="test">
   <item name="*">
   <model src="models/maintenance.xql"/>
 </item>
</site>;:)

if ($curtain and (xdb:get-current-user() != 'admin')) then 
  gen:process($exist:root, $exist:prefix, $exist:controller, $exist:path, 'fr', true(), $access, $actions, $curtain)
else
  gen:process($exist:root, $exist:prefix, $exist:controller, $exist:path, 'fr', true(), $access, $actions, $mapping)