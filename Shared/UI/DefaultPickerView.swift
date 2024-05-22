//
//  Copyright (c) 2011-2024, Zingaya, Inc. All rights reserved.
//

import UIKit

final class DefaultPickerView: UIPickerView {

    var data: [String] = []
    var selectedValue: String {
        data[self.selectedRow(inComponent: 0)]
    }

    func configure(with data: [String], defaultRow: Int) {
        self.data = data
        selectRow(defaultRow, inComponent: 0, animated: false)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    private func sharedInit() {
        delegate = self
        dataSource = self
        tintColor = .white
        layer.borderWidth = 1
        layer.borderColor = Color.secondaryWhite.cgColor
        layer.cornerRadius = Theme.defaultCornerRadius
    }
}

extension DefaultPickerView: UIPickerViewDelegate {

}

extension DefaultPickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        data.count
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        NSAttributedString(string: data[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        data[row]
    }
}
