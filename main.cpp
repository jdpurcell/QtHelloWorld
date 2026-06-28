#include <QtWidgets>

class MainWindow : public QMainWindow {
public:
    explicit MainWindow(QWidget *parent = nullptr) : QMainWindow{parent} {
        setWindowTitle("Hello World");
        setCentralWidget(new QWidget);
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MainWindow win;
    win.show();
    return app.exec();
}
