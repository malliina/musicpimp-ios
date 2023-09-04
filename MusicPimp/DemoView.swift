
import Foundation

class DemoView: UIViewController {
    let label1 = UILabel()
    let textView = UITextField()
    let label2 = UILabel()
    let label3 = UILabel()
    let scroll = UIScrollView()
    let content = UIView()
    let button = PimpButton(title: "Jee")
    
    func buttonClicked(sender: UIButton) {
        print("haa")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.onTouchUpInside = buttonClicked
        edgesForExtendedLayout = []
        scroll.backgroundColor = .magenta
        label1.text = "text1"
        label1.backgroundColor = .green
        label2.text = "text2"
        label2.backgroundColor = .orange
        label3.text = "text3"
        label3.backgroundColor = .blue
        textView.placeholder = "huu haa"
        
        scroll.addSubview(content)
        view.addSubview(scroll)
        [label1, label2, label3, textView, button].forEach { (label) in
            content.addSubview(label)
            label.snp.makeConstraints({ (make) in
                // The height is not mandatory, but good for demo purposes
                make.height.equalTo(400)
                make.leading.trailing.equalTo(content).inset(8)
            })
        }
        scroll.snp.makeConstraints { (make) in
            make.edges.equalTo(view).inset(UIEdgeInsets.zero)
        }
        content.snp.makeConstraints { (make) in
            make.edges.equalTo(scroll).inset(UIEdgeInsets.zero)
            make.width.equalTo(scroll)
        }
        button.snp.makeConstraints { (make) in
            make.top.equalTo(content).inset(8)
        }
        label1.snp.makeConstraints { (make) in
            make.top.equalTo(button).inset(8)
        }
        textView.snp.makeConstraints { (make) in
            make.top.equalTo(label1.snp.bottom).offset(8)
        }
        label2.snp.makeConstraints { (make) in
            make.top.equalTo(textView.snp.bottom).offset(8)
        }
        label3.snp.makeConstraints { (make) in
            make.top.equalTo(label2.snp.bottom).offset(8)
            // required for scrolling to work
            make.bottom.equalTo(content).inset(8)
        }
    }
}
