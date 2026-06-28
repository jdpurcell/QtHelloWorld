#include <QtWidgets>

class MainWindow : public QMainWindow {
public:
    explicit MainWindow(QWidget *parent = nullptr) : QMainWindow{parent} {
        setWindowTitle("App");
        auto *central = new QWidget;
        auto *layout = new QVBoxLayout(central);
        auto *button = new QPushButton("Toggle Fullscreen");
        connect(button, &QPushButton::clicked, this, [this]() {
            if (isFullScreen())
                showNormal();
            else
                showFullScreen();
        });
        layout->addWidget(button);
        setCentralWidget(central);
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MainWindow win;
    win.show();
    return app.exec();
}
