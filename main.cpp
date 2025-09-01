#include <QtWidgets>

class MainWindow : public QMainWindow {
public:
    MainWindow(QWidget *parent = nullptr) : QMainWindow{parent} {
        setWindowTitle("Hello World");
        setCentralWidget(new QWidget(this));
        resize(400, 300);

        auto *checkableAction = new QAction(QIcon::fromTheme(QIcon::ThemeIcon::ZoomFitBest), "Checkable", this);
        checkableAction->setCheckable(true);
        connect(checkableAction, &QAction::toggled, this, [this](bool checked) {
            setWindowTitle(checked ? "Checked" : "Unchecked");
        });

        centralWidget()->addAction(new QAction(QIcon::fromTheme(QIcon::ThemeIcon::DocumentNew), "First Item", this));
        centralWidget()->addAction(checkableAction);
        centralWidget()->addAction(new QAction(QIcon::fromTheme(QIcon::ThemeIcon::HelpAbout), "Last Item", this));
        centralWidget()->setContextMenuPolicy(Qt::ActionsContextMenu);
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MainWindow *win = new MainWindow();
    app.setAttribute(Qt::AA_DontShowIconsInMenus, false);
    win->show();
    return app.exec();
}
