//
//  ViewerThumbnailGridStep.swift
//  cooViewer
//
//  Pure grid-advance logic shared by ThumbnailController's cell-fill
//  animation (setImageCellWithInfo:/setBookmarkImageCellWithInfo:),
//  which previously inlined four mirror variants (back x readFromLeft)
//  of the same "step one cell, wrap at the row edge, stop past the last
//  row" walk, plus two more in the bookmark variant. The performSelector
//  recursion and doCount/stop cancellation stay in the controller - this
//  type only answers "where is the next cell, and are we off the grid?".
//
//  Direction mapping (matching the original branches): reading
//  left-to-right walks columns rightward and rows downward; right-to-left
//  walks columns leftward. Paging back reverses both axes.
//

import Foundation

@objc final class ViewerThumbnailGridStep: NSObject {

	@objc let column: Int32
	@objc let row: Int32
	@objc let done: Bool

	private init(column: Int32, row: Int32, done: Bool) {
		self.column = column
		self.row = row
		self.done = done
		super.init()
	}

	/// The cell position after `(column, row)` in a `columns x rows`
	/// matrix, walking in the direction given by `(back, readFromLeft)`.
	/// `done` is true when the walk stepped past the grid's last (or,
	/// going back, first) row - the returned column/row then hold the
	/// wrapped values the original code computed before its bounds check.
	@objc(stepAfterColumn:row:columns:rows:back:readFromLeft:)
	static func step(afterColumn column: Int32, row: Int32, columns: Int32, rows: Int32, back: Bool, readFromLeft: Bool) -> ViewerThumbnailGridStep {
		let columnStep: Int32 = (readFromLeft != back) ? 1 : -1
		var newColumn = column + columnStep
		var newRow = row
		if newColumn < 0 || newColumn == columns {
			newRow += back ? -1 : 1
			newColumn = columnStep > 0 ? 0 : columns - 1
			if newRow < 0 || newRow == rows {
				return ViewerThumbnailGridStep(column: newColumn, row: newRow, done: true)
			}
		}
		return ViewerThumbnailGridStep(column: newColumn, row: newRow, done: false)
	}
}
