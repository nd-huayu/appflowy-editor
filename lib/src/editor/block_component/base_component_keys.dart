/// the delta of the block component
///
/// its value is a string of json format, e.g. '{"insert":"Hello World"}'
/// for more information, please refer to https://quilljs.com/docs/delta/
const blockComponentDelta = 'delta';

/// the background of the block component
///
/// its value is a string of hex code, e.g. '#00000000'
const blockComponentBackgroundColor = 'bgColor';

/// the text direction of the block component
///
/// its value must be one of the following:
///   - [blockComponentTextDirectionLTR] or 'ltr': left to right
///   - [blockComponentTextDirectionRTL] or 'rtl': right to left
///   - [blockComponentTextDirectionAuto] or auto: depends on the text
///
/// only works for the block with text,
///   e.g. paragraph, heading, quote, to-do list, bulleted list, numbered list
const blockComponentTextDirection = 'textDirection';
const blockComponentTextDirectionAuto = 'auto';
const blockComponentTextDirectionLTR = 'ltr';
const blockComponentTextDirectionRTL = 'rtl';

/// 文本对齐
const blockComponentTextAlign = 'align';
const blockComponentTextAlignLeft = 'left';
const blockComponentTextAlignCenter = 'center';
const blockComponentTextAlignRight = 'right';
const blockComponentTextAlignJustify = 'justify';

/// 文本行高
const blockComponentTextHeight = 'line_height';

/// text align
///
/// its value must be one of the following:
///  - left, right, center.
const blockComponentAlign = 'align';

/// 文本段前段后
const blockPreParagraph = 'pre_paragraph';
const blockAfterParagraph = 'after_paragraph';

/// 缩进
const blockIndent = 'indent';
