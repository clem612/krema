-- -src / shell / previewcontroller.cpp++ + src / shell / previewcontroller.cpp @ @-539, 6 + 539, 6 @ @ const auto edge = m_dockView->platform()->edge();
const bool vertical = (edge == DockPlatform::Edge::Left || edge == DockPlatform::Edge::Right);

constexpr qreal pad = 8;
constexpr qreal preview_margin = 12;
@ @-578, 5 + 578,
    5 @ @
    // Vertical placement: Above or Below the icon
    if (edge == DockPlatform::Edge::Top)
{
    -m_contentY = m_itemGlobalY + m_itemHeight + preview_margin;
    +m_contentY = m_dockHeight + preview_margin;
}
else
{
    -m_contentY = m_itemGlobalY - m_contentHeight - preview_margin;
    +m_contentY = m_dockHeight - m_contentHeight - preview_margin;
}
}
