<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xhtml="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		exclude-result-prefixes="xhtml xsl xs">

  <xsl:param name="title"/>
  <xsl:param name="presdate"/>
  <xsl:param name="author"/>
  <xsl:param name="company"/>
  <xsl:param name="style"/>
  <xsl:param name="transitions"/>
  <xsl:param name="fadeDuration"/>
  <xsl:param name="incrDuration"/>
  <xsl:param name="automatic"/>
  <xsl:param name="playLoop"/>
  <xsl:param name="playDelay"/>
  <xsl:param name="audioSupport"/>
  <xsl:param name="audioVolume"/>
  <xsl:param name="audioError"/>
  <xsl:param name="audioDebug"/>

  <xsl:output method="html"
	      version="1.0"
	      encoding="UTF-8"
	      doctype-public="-//W3C//DTD XHTML 1.1//EN"
	      doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" indent="yes"/>

  <xsl:strip-space elements="*"/>

  <!-- Identity template -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="section">
    <xsl:param name="current"/>
    <xsl:for-each select="child::node()[name() != 'h1' and name() != 'h2' and name() != 'h3' and name() != 'h4' and name() != 'h5' and name() != 'h6' and
			  (preceding::xhtml:h1|preceding::xhtml:h2|preceding::xhtml:h3|preceding::xhtml:h4|preceding::xhtml:h5|preceding::xhtml:h6)[last()] = $current]">
      <xsl:copy>
	<xsl:copy-of select="@*"/>
	<xsl:call-template name="section">
	  <xsl:with-param name="current" select="$current"/>
	</xsl:call-template>
      </xsl:copy>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="slides">
    <xsl:for-each select="//xhtml:h1|//xhtml:h2|//xhtml:h3|//xhtml:h4|//xhtml:h5|//xhtml:h6">
      <div class="slide">
	<h1><xsl:apply-templates select="@*|node()"/></h1>
	<div class="slidecontent">
	  <xsl:variable name="current" select="."/>
	  <xsl:for-each select="following-sibling::node()[name() != 'h1' and name() != 'h2' and name() != 'h3' and name() != 'h4' and name() != 'h5' and name() != 'h6' and
				(preceding::xhtml:h1|preceding::xhtml:h2|preceding::xhtml:h3|preceding::xhtml:h4|preceding::xhtml:h5|preceding::xhtml:h6)[last()] = $current]">
	    <xsl:copy>
	      <xsl:copy-of select="@*"/>
	      <xsl:call-template name="section">
		<xsl:with-param name="current" select="$current"/>
	      </xsl:call-template>
	    </xsl:copy>
	  </xsl:for-each>
	</div>
      </div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="xhtml:head">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <!-- metadata -->
      <meta name="generator" content="S5" />
      <meta name="version" content="S5 1.3" />
      <xsl:if test="$presdate"><meta name="presdate" content="{$presdate}"/></xsl:if>
      <xsl:if test="$author"><meta name="author" content="{$author}"/></xsl:if>
      <xsl:if test="$company"><meta name="company" content="{$company}"/></xsl:if>
      <!-- configuration parameters -->
      <meta name="defaultView" content="slideshow" />
      <meta name="controlVis" content="hidden" />
      <!-- configuration transition parameters -->
      <xsl:if test="$transitions"><meta name="tranSitions" content="{$transitions}"/></xsl:if>
      <xsl:if test="$fadeDuration"><meta name="fadeDuration" content="{$fadeDuration}"/></xsl:if>
      <xsl:if test="$incrDuration"><meta name="incrDuration" content="{$incrDuration}"/></xsl:if>
      <!-- configuration autoplay parameters -->
      <xsl:if test="$automatic"><meta name="autoMatic" content="{$automatic}"/></xsl:if>
      <xsl:if test="$playLoop"><meta name="playLoop" content="{$playLoop}"/></xsl:if>
      <xsl:if test="$playDelay"><meta name="playDelay" content="{$playDelay}"/></xsl:if>
      <!-- configuration audio parameters -->
      <xsl:if test="$audioSupport"><meta name="audioSupport" content="{$audioSupport}"/></xsl:if>
      <xsl:if test="$audioVolume"><meta name="audioVolume" content="{$audioVolume}"/></xsl:if>
      <xsl:if test="$audioError"><meta name="audioError" content="{$audioError}"/></xsl:if>
      <xsl:if test="$audioDebug"><meta name="audioDebug" content="{$audioDebug}"/></xsl:if>
      <!-- style sheet links -->
      <link rel="stylesheet" href="/_/filter/s5/ui/{$style}/slides.css" type="text/css" media="projection" id="slideProj" />
      <link rel="stylesheet" href="/_/filter/s5/ui/{$style}/outline.css" type="text/css" media="screen" id="outlineStyle" />
      <link rel="stylesheet" href="/_/filter/s5/ui/{$style}/print.css" type="text/css" media="print" id="slidePrint" />
      <link rel="stylesheet" href="/_/filter/s5/ui/{$style}/opera.css" type="text/css" media="projection" id="operaFix" />
      <script src="/_/filter/s5/ui/{$style}/slides.js" type="text/javascript"></script>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xhtml:body">
    <xsl:copy>
      <div class="layout">
	<div id="controls"><!-- DO NOT EDIT --></div>
	<div id="currentSlide"><!-- DO NOT EDIT --></div>
	<div id="header"></div>
	<div id="footer">
	  <h1><xsl:value-of select="$presdate"/></h1>
	  <h2><xsl:value-of select="$title"/></h2>
	</div>
      </div>
      <div class="presentation">
	<xsl:call-template name="slides"/>
      </div>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
