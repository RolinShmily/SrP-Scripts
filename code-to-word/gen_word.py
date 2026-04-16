"""
批量将代码文件转为带语法高亮的 Word 文档
依赖安装: pip install pygments spire.doc
"""

import os
from pygments import highlight
from pygments.lexers import MatlabLexer, get_lexer_for_filename
from pygments.formatters import RtfFormatter
from spire.doc import Document, FileFormat


CODE_DIR = os.path.dirname(os.path.abspath(__file__))
FONT_SIZE = r"\fs21"  # 10.5pt ≈ fs21


def code_to_rtf(code: str, lexer) -> str:
    """将代码转为 RTF 格式（带语法高亮）"""
    formatter = RtfFormatter(fontface="Consolas")
    rtf_text = highlight(code, lexer, formatter)
    # 设置字体大小
    rtf_text = rtf_text.replace(r"\f0", r"\f0" + FONT_SIZE)
    return rtf_text


def process_file(filepath: str) -> None:
    """将单个代码文件转为 Word 文档"""
    basename = os.path.basename(filepath)
    filename_no_ext = os.path.splitext(basename)[0]
    output_path = os.path.join(CODE_DIR, filename_no_ext + ".docx")

    # 读取代码
    with open(filepath, "r", encoding="utf-8") as f:
        code = f.read()

    # 自动识别语言
    try:
        lexer = get_lexer_for_filename(basename)
    except Exception:
        lexer = MatlabLexer()

    # 转为 RTF
    rtf_text = code_to_rtf(code, lexer)

    # 生成 Word 文档（新建空文档，不加载源文件）
    doc = Document()
    section = doc.AddSection()
    para = section.AddParagraph()
    para.AppendRTF(rtf_text)
    doc.SaveToFile(output_path, FileFormat.Docx2016)
    doc.Close()

    print(f"[OK] {basename} -> {filename_no_ext}.docx")


def main():
    # 支持的代码文件扩展名
    extensions = {".m", ".py", ".c", ".cpp", ".java", ".cs", ".js", ".ts", ".go", ".rs"}
    # 排除自身
    self_name = os.path.basename(os.path.abspath(__file__))

    files = [
        f for f in os.listdir(CODE_DIR)
        if os.path.isfile(os.path.join(CODE_DIR, f))
        and f != self_name
        and os.path.splitext(f)[1].lower() in extensions
    ]

    if not files:
        print("未找到代码文件")
        return

    print(f"找到 {len(files)} 个代码文件，开始转换...\n")

    for f in sorted(files):
        filepath = os.path.join(CODE_DIR, f)
        try:
            process_file(filepath)
        except Exception as e:
            print(f"[FAIL] {f}: {e}")

    print(f"\n完成！文件保存在: {CODE_DIR}")


if __name__ == "__main__":
    main()
