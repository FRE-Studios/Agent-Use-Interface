<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:a="https://agentuseinterface.org/schema/0.1">

  <sch:title>Agent Use Interface (AUI) v0.1 Semantic Rules</sch:title>
  <sch:ns prefix="a" uri="https://agentuseinterface.org/schema/0.1"/>
  <!--
    This Schematron validates same-document semantic rules. Cross-document
    checks (for example, href detail-file id matching) must be validated at
    detail-file fetch time.
  -->

  <sch:pattern id="task-inline-reference-forms">
    <sch:rule context="a:aui/a:tasks/a:task[not(@href)]">
      <sch:assert test="a:base-path">
        Inline task (no href) MUST include base-path.
      </sch:assert>
      <sch:assert test="a:parameters">
        Inline task (no href) MUST include parameters.
      </sch:assert>
    </sch:rule>

    <sch:rule context="a:aui/a:tasks/a:task[@href]">
      <sch:assert test="not(a:base-path)">
        Reference task (has href) MUST omit base-path.
      </sch:assert>
      <sch:assert test="not(a:parameters)">
        Reference task (has href) MUST omit parameters.
      </sch:assert>
      <sch:assert test="not(a:examples)">
        Reference task (has href) MUST omit examples.
      </sch:assert>
      <sch:assert test="not(@output)">
        Reference task (has href) MUST omit output; output is defined in the detail file.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="enum-options">
    <sch:rule context="a:param[@type='enum']">
      <sch:assert test="a:options">
        Enum parameters MUST include options.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

</sch:schema>
