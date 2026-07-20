from pathlib import Path
import json
try:
    from tree_sitter import Language, Parser
    import tree_sitter_java
except ImportError:  # permits inspect/audit on a bare Python install; production uses declared dependency
    Language = Parser = tree_sitter_java = None

def _parser():
    if Parser is None: return None
    p = Parser(Language(tree_sitter_java.language()))
    return p

def scan_project(root: Path) -> dict:
    root = root.resolve()
    java_root = root / "src/main/java"
    resources = root / "src/main/resources"
    manifest = {"project_root": str(root), "build_system": "maven" if (root/"pom.xml").exists() else "gradle", "java_source_root": str(java_root), "resource_root": str(resources), "entities": [], "enums": [], "converters": [], "relations": [], "jsonb_fields": [], "migrations": []}
    parser = _parser()
    for file in java_root.rglob("*.java") if java_root.exists() else []:
        text = file.read_text(encoding="utf-8")
        tree = parser.parse(text.encode()) if parser else None
        package = next((n.text.decode() for n in tree.root_node.children if n.type == "package_declaration"), "") if tree else ""
        classes = [n for n in tree.root_node.children if n.type in ("class_declaration", "enum_declaration")] if tree else []
        if not tree:
            import re
            package = (re.search(r"package\s+([\w.]+)", text) or ["", ""])[1]
            classes = []
            for kind, name in re.findall(r"@(Entity|Embeddable).*?class\s+(\w+)", text, re.S):
                manifest["entities"].append({"name":name,"package":package,"file":str(file.relative_to(root)),"annotations":["@"+kind],"table":_annotation_value(text,"@Table","name") or name.lower(),"fields":_fields(text,None)})
            for name in re.findall(r"enum\s+(\w+)", text): manifest["enums"].append({"name":name,"package":package,"file":str(file.relative_to(root))})
        for node in classes:
            name = next((c.text.decode() for c in node.children if c.type == "identifier"), file.stem)
            annotations = [c.text.decode() for c in node.children if c.type == "modifiers"]
            record = {"name": name, "package": package, "file": str(file.relative_to(root)), "annotations": annotations}
            if "@Entity" in text and node.type == "class_declaration":
                record["table"] = _annotation_value(text, "@Table", "name") or name.lower()
                record["fields"] = _fields(text, node)
                manifest["entities"].append(record)
            elif node.type == "enum_declaration": manifest["enums"].append(record)
        if "@Converter" in text: manifest["converters"].append({"name": file.stem, "file": str(file.relative_to(root))})
        for field in _fields(text, None):
            if field.get("column_definition", "").lower() == "jsonb": manifest["jsonb_fields"].append({"file": str(file.relative_to(root)), **field})
        if "@ManyTo" in text or "@OneTo" in text: manifest["relations"].append({"file": str(file.relative_to(root)), "annotations": [x for x in ("ManyToOne", "OneToMany", "ManyToMany", "OneToOne", "JoinColumn", "JoinTable") if "@"+x in text]})
    manifest["migrations"] = [str(x.relative_to(root)) for x in root.rglob("*.sql")]
    for key in ("entities", "enums", "converters", "relations", "jsonb_fields", "migrations"): manifest[key+"_found"] = len(manifest[key])
    return manifest

def _annotation_value(text, annotation, key):
    import re
    m = re.search(re.escape(annotation)+r"\s*\([^)]*?"+key+r"\s*=\s*\"([^\"]+)", text)
    return m.group(1) if m else None

def _fields(text, node):
    import re
    result=[]
    for m in re.finditer(r"(?P<ann>(?:\s*@[^\n]+\n)*)\s*(?:private|protected|public)\s+(?P<type>[\w<>?, ]+)\s+(?P<name>\w+)\s*(?:=|;)", text):
        ann=m.group("ann")
        col=re.search(r"@Column\s*\(([^)]*)", ann)
        options = col.group(1) if col else ""
        name_match = re.search(r'name\s*=\s*\"([^\"]+)', options)
        definition_match = re.search(r'columnDefinition\s*=\s*\"([^\"]+)', options)
        result.append({"name": m.group("name"), "java_type": m.group("type").strip(),
                       "column": name_match.group(1) if name_match else m.group("name"),
                       "nullable": "nullable = false" not in options,
                       "column_definition": definition_match.group(1) if definition_match else ""})
    return result
