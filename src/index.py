import sys
import os
import subprocess
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QTableWidget, QTableWidgetItem,
    QPushButton, QLineEdit, QLabel, QProgressBar, QMessageBox, QHeaderView, QInputDialog, QListWidget, QListWidgetItem, QSplitter, QSizePolicy
)
from PyQt5.QtCore import Qt, QThread, pyqtSignal, QSize
from PyQt5.QtGui import QPalette, QColor, QFont

class GitScannerThread(QThread):
    progress = pyqtSignal(int)
    repo_found = pyqtSignal(str)
    scan_complete = pyqtSignal()

    def run(self):
        home_dir = os.path.expanduser("~")
        total_dirs = sum([len(dirs) for _, dirs, _ in os.walk(home_dir)])
        scanned = 0
        for root, dirs, _ in os.walk(home_dir):
            if ".git" in dirs:
                self.repo_found.emit(root)
            scanned += len(dirs)
            self.progress.emit(int((scanned / total_dirs) * 100) if total_dirs > 0 else 100)
        self.scan_complete.emit()

class GitStatusThread(QThread):
    status_ready = pyqtSignal(str, str, str, str, str)  # repo_path, emoji, name, truncated_path, status_msg
    def __init__(self, repo_path):
        super().__init__()
        self.repo_path = repo_path
    def run(self):
        try:
            remote = subprocess.run([
                "git", "-C", self.repo_path, "config", "--get", "remote.origin.url"
            ], capture_output=True, text=True)
            if remote.returncode == 0 and remote.stdout.strip():
                name = remote.stdout.strip().split('/')[-1].replace('.git','')
            else:
                name = os.path.basename(self.repo_path)
        except Exception:
            name = os.path.basename(self.repo_path)
        # Get status details
        try:
            status = subprocess.run([
                "git", "-C", self.repo_path, "status", "--porcelain"
            ], capture_output=True, text=True)
            changed_files = [line for line in status.stdout.strip().splitlines() if line]
            n_changed = len(changed_files)
            branch = subprocess.run([
                "git", "-C", self.repo_path, "status", "-sb"
            ], capture_output=True, text=True)
            ahead = 0
            if branch.stdout:
                import re
                m = re.search(r'\[ahead (\d+)', branch.stdout)
                if m:
                    ahead = int(m.group(1))
            # Emoji and message
            if n_changed == 0 and ahead == 0:
                emoji = "✅"
                status_msg = "Clean"
            elif n_changed > 0 and ahead == 0:
                emoji = "✏️"
                status_msg = f"{n_changed} file{'s' if n_changed > 1 else ''} modified"
            elif n_changed == 0 and ahead > 0:
                emoji = "⬆️"
                status_msg = f"{ahead} commit{'s' if ahead > 1 else ''} ahead"
            else:
                emoji = "✏️⬆️"
                status_msg = f"{n_changed} file{'s' if n_changed > 1 else ''} modified, {ahead} commit{'s' if ahead > 1 else ''} ahead"
        except Exception:
            emoji = "❓"
            status_msg = "Unknown"
        path = self.repo_path
        if len(path) > 38:
            path = "..." + path[-35:]
        self.status_ready.emit(self.repo_path, emoji, name, path, status_msg)

class GitManager(QMainWindow):
    def __init__(self):
        super().__init__()
        self.threads = []  # Keep references to all threads
        self.setWindowTitle("GitCompass - Git Repository Manager")
        self.setGeometry(100, 100, 1100, 650)
        self.repos = []
        self.repo_status = {}  # repo_path: (emoji, name, truncated_path, status_msg)
        self.status_threads = []  # Keep references to status threads
        self.selected_repo = None
        self.init_ui()

    def show_welcome(self):
        import os
        welcome_flag = os.path.expanduser("~/.gitcompass_welcomed")
        if not os.path.exists(welcome_flag):
            QMessageBox.information(self, "Welcome to GitCompass!",
                "Welcome to GitCompass!\n\nA beautiful, Discord-themed Git repository manager.\n\nSelect a repository and use the action buttons below to get started.\n\nEnjoy hacking!\n\n- Goal651")
            with open(welcome_flag, "w") as f:
                f.write("1\n")

    def init_ui(self):
        self.set_discord_theme()
        splitter = QSplitter(Qt.Horizontal)
        self.setCentralWidget(splitter)

        # Sidebar: Repo list
        sidebar_widget = QWidget()
        sidebar_layout = QVBoxLayout(sidebar_widget)
        sidebar_layout.setContentsMargins(8, 8, 8, 8)
        sidebar_layout.setSpacing(8)
        sidebar_label = QLabel("Repositories")
        sidebar_label.setFont(QFont("Arial", 12, QFont.Bold))
        sidebar_layout.addWidget(sidebar_label)
        self.repo_list = QListWidget()
        self.repo_list.setAlternatingRowColors(True)
        self.repo_list.setStyleSheet('''
            QListWidget {
                background-color: #2f3136;
                color: #fff;
                border-radius: 8px;
                border: 1px solid #23272a;
                font-size: 14px;
            }
            QListWidget::item:selected {
                background-color: #5865f2;
                color: #fff;
            }
            QListWidget::item:hover {
                background-color: #4752c4;
            }
        ''')
        self.repo_list.setFixedWidth(260)
        self.repo_list.itemClicked.connect(self.sidebar_select_repo)
        sidebar_layout.addWidget(self.repo_list)
        sidebar_layout.addStretch(1)
        splitter.addWidget(sidebar_widget)

        # Main panel: Actions and details
        main_panel = QWidget()
        main_layout = QVBoxLayout(main_panel)
        main_layout.setContentsMargins(16, 16, 16, 16)
        main_layout.setSpacing(12)

        # Search/filter bar
        search_layout = QHBoxLayout()
        self.search_bar = QLineEdit()
        self.search_bar.setPlaceholderText("Search repositories by name or path...")
        self.search_bar.textChanged.connect(self.filter_repos)
        search_layout.addWidget(QLabel("Search:"))
        search_layout.addWidget(self.search_bar)
        main_layout.addLayout(search_layout)

        # Repo details/status
        self.repo_title = QLabel("")
        self.repo_title.setFont(QFont("Arial", 14, QFont.Bold))
        main_layout.addWidget(self.repo_title)
        self.repo_status_label = QLabel("")
        main_layout.addWidget(self.repo_status_label)

        # Button bar for repo actions
        btn_layout = QHBoxLayout()
        btn_layout.setSpacing(10)
        self.commit_btn = QPushButton("📝 Add & Commit")
        self.commit_btn.setToolTip("Add all changes and commit (Ctrl+C)")
        self.commit_btn.clicked.connect(self.add_commit)
        self.commit_btn.setShortcut("Ctrl+C")
        btn_layout.addWidget(self.commit_btn)
        self.push_btn = QPushButton("⬆️ Push")
        self.push_btn.setToolTip("Push to remote (Ctrl+P)")
        self.push_btn.clicked.connect(self.push)
        self.push_btn.setShortcut("Ctrl+P")
        btn_layout.addWidget(self.push_btn)
        self.pull_btn = QPushButton("⬇️ Pull")
        self.pull_btn.setToolTip("Pull latest changes (Ctrl+L)")
        self.pull_btn.clicked.connect(self.pull)
        self.pull_btn.setShortcut("Ctrl+L")
        btn_layout.addWidget(self.pull_btn)
        self.status_btn = QPushButton("📋 Status")
        self.status_btn.setToolTip("Show git status (Ctrl+S)")
        self.status_btn.clicked.connect(self.show_status)
        self.status_btn.setShortcut("Ctrl+S")
        btn_layout.addWidget(self.status_btn)
        self.log_btn = QPushButton("📜 Log")
        self.log_btn.setToolTip("Show recent commit log (Ctrl+G)")
        self.log_btn.clicked.connect(self.show_log)
        self.log_btn.setShortcut("Ctrl+G")
        btn_layout.addWidget(self.log_btn)
        self.stash_btn = QPushButton("📦 Stash")
        self.stash_btn.setToolTip("Stash changes (Ctrl+T)")
        self.stash_btn.clicked.connect(self.stash)
        self.stash_btn.setShortcut("Ctrl+T")
        btn_layout.addWidget(self.stash_btn)
        self.pop_btn = QPushButton("📤 Pop Stash")
        self.pop_btn.setToolTip("Pop latest stash (Ctrl+O)")
        self.pop_btn.clicked.connect(self.pop_stash)
        self.pop_btn.setShortcut("Ctrl+O")
        btn_layout.addWidget(self.pop_btn)
        self.advlog_btn = QPushButton("🔍 Advanced Log")
        self.advlog_btn.setToolTip("Show advanced log (Ctrl+A)")
        self.advlog_btn.clicked.connect(self.advanced_log)
        self.advlog_btn.setShortcut("Ctrl+A")
        btn_layout.addWidget(self.advlog_btn)
        self.delete_btn = QPushButton("🗑️ Delete Repo")
        self.delete_btn.setToolTip("Delete selected repository")
        self.delete_btn.clicked.connect(self.delete_repo)
        btn_layout.addWidget(self.delete_btn)
        self.clone_btn = QPushButton("➕ Clone Repo")
        self.clone_btn.setToolTip("Clone a new repository")
        self.clone_btn.clicked.connect(self.clone_repo)
        btn_layout.addWidget(self.clone_btn)
        self.batch_btn = QPushButton("📊 Batch Status")
        self.batch_btn.setToolTip("Show status for all repositories")
        self.batch_btn.clicked.connect(self.batch_status)
        btn_layout.addWidget(self.batch_btn)
        self.export_btn = QPushButton("💾 Export")
        self.export_btn.setToolTip("Export repository list/statuses")
        self.export_btn.clicked.connect(self.export_repos)
        btn_layout.addWidget(self.export_btn)
        self.import_btn = QPushButton("📂 Import")
        self.import_btn.setToolTip("Import repository list/statuses")
        self.import_btn.clicked.connect(self.import_repos)
        btn_layout.addWidget(self.import_btn)
        self.settings_btn = QPushButton("⚙️ Settings")
        self.settings_btn.setToolTip("Settings/configuration")
        self.settings_btn.clicked.connect(self.show_settings)
        btn_layout.addWidget(self.settings_btn)
        self.help_btn = QPushButton("❓ Help/About")
        self.help_btn.setToolTip("Show help/about dialog")
        self.help_btn.clicked.connect(self.show_help)
        btn_layout.addWidget(self.help_btn)
        main_layout.addLayout(btn_layout)

        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setValue(0)
        main_layout.addWidget(self.progress_bar)

        splitter.addWidget(main_panel)
        splitter.setSizes([260, 800])

        # Start scanning
        self.scanner = GitScannerThread()
        self.threads.append(self.scanner)
        self.scanner.progress.connect(self.progress_bar.setValue)
        self.scanner.repo_found.connect(self.add_repo)
        self.scanner.scan_complete.connect(lambda: self.progress_bar.setValue(100))
        self.scanner.start()

        # Show welcome dialog on first launch
        self.show_welcome()

    def set_discord_theme(self):
        palette = QPalette()
        palette.setColor(QPalette.Window, QColor(54, 57, 63))  # Discord dark background
        palette.setColor(QPalette.WindowText, Qt.white)
        palette.setColor(QPalette.Base, QColor(47, 49, 54))
        palette.setColor(QPalette.AlternateBase, QColor(54, 57, 63))
        palette.setColor(QPalette.ToolTipBase, Qt.white)
        palette.setColor(QPalette.ToolTipText, Qt.white)
        palette.setColor(QPalette.Text, Qt.white)
        palette.setColor(QPalette.Button, QColor(88, 101, 242))  # Discord blurple
        palette.setColor(QPalette.ButtonText, Qt.white)
        palette.setColor(QPalette.Highlight, QColor(88, 101, 242))
        palette.setColor(QPalette.HighlightedText, Qt.white)
        palette.setColor(QPalette.BrightText, Qt.red)
        self.setPalette(palette)
        self.setStyleSheet('''
            QTableWidget, QLineEdit, QLabel, QProgressBar {
                font-size: 14px;
            }
            QTableWidget {
                background-color: #36393f;
                color: #fff;
                gridline-color: #23272a;
                selection-background-color: #5865f2;
                selection-color: #fff;
            }
            QHeaderView::section {
                background-color: #23272a;
                color: #fff;
                font-weight: bold;
            }
            QLineEdit {
                background-color: #23272a;
                color: #fff;
                border: 1px solid #5865f2;
                border-radius: 4px;
                padding: 4px;
            }
            QPushButton {
                background-color: #5865f2;
                color: #fff;
                border-radius: 4px;
                padding: 6px 12px;
            }
            QPushButton:hover {
                background-color: #4752c4;
            }
            QProgressBar {
                background-color: #23272a;
                color: #fff;
                border-radius: 4px;
                text-align: center;
            }
            QProgressBar::chunk {
                background-color: #5865f2;
            }
        ''')

    def add_repo(self, repo_path):
        self.repos.append(repo_path)
        # Start a thread to get status and name
        status_thread = GitStatusThread(repo_path)
        self.status_threads.append(status_thread)
        self.threads.append(status_thread)
        status_thread.status_ready.connect(self.add_repo_row)
        status_thread.start()

    def add_repo_row(self, repo_path, emoji, name, path, status_msg):
        self.repo_status[repo_path] = (emoji, name, path, status_msg)
        self.refresh_sidebar()
        self.refresh_main_panel()

    def refresh_sidebar(self):
        filter_text = self.search_bar.text().lower()
        self.repo_list.clear()
        for repo_path in self.repos:
            emoji, name, path, status_msg = self.repo_status.get(repo_path, ("", "", repo_path, ""))
            if filter_text and filter_text not in name.lower() and filter_text not in repo_path.lower():
                continue
            item = QListWidgetItem(f"{emoji} {name}")
            item.setToolTip(f"{path}\n{status_msg}")
            item.setData(Qt.UserRole, repo_path)
            self.repo_list.addItem(item)
        # Reselect previously selected repo if possible
        if self.selected_repo:
            for i in range(self.repo_list.count()):
                if self.repo_list.item(i).data(Qt.UserRole) == self.selected_repo:
                    self.repo_list.setCurrentRow(i)
                    break

    def refresh_main_panel(self):
        repo = self.get_selected_repo()
        if not repo:
            self.repo_title.setText("")
            self.repo_status_label.setText("")
            if hasattr(self, 'changed_files_widget'):
                self.changed_files_widget.hide()
            for btn in [self.commit_btn, self.push_btn, self.pull_btn, self.status_btn, self.log_btn, self.stash_btn, self.pop_btn, self.advlog_btn, self.delete_btn]:
                btn.setEnabled(False)
            return
        emoji, name, path, status_msg, changed_files = self.repo_status.get(repo, ("", "", repo, "", []))
        self.repo_title.setText(f"{emoji} {name}")
        self.repo_status_label.setText(f"<span style='font-size:15px;'><b>Path:</b> {path}<br><b>Status:</b> {status_msg}</span>")
        for btn in [self.commit_btn, self.push_btn, self.pull_btn, self.status_btn, self.log_btn, self.stash_btn, self.pop_btn, self.advlog_btn, self.delete_btn]:
            btn.setEnabled(True)
        # Changed files widget
        from PyQt5.QtWidgets import QTableWidget, QTableWidgetItem, QVBoxLayout, QGroupBox
        if not hasattr(self, 'changed_files_group'):
            self.changed_files_group = QGroupBox("Changed Files")
            self.changed_files_group.setStyleSheet('''
                QGroupBox {
                    font-size: 16px;
                    font-weight: bold;
                    border: 2px solid #5865f2;
                    border-radius: 8px;
                    margin-top: 10px;
                    background-color: #23272a;
                    color: #fff;
                }
                QGroupBox:title {
                    subcontrol-origin: margin;
                    left: 10px;
                    padding: 0 3px 0 3px;
                }
            ''')
            self.changed_files_widget = QTableWidget(0, 3)
            self.changed_files_widget.setHorizontalHeaderLabels(["", "File", "Status"])
            self.changed_files_widget.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
            self.changed_files_widget.setEditTriggers(QTableWidget.NoEditTriggers)
            self.changed_files_widget.setAlternatingRowColors(True)
            self.changed_files_widget.setStyleSheet('''
                QTableWidget {
                    font-size: 15px;
                    background-color: #36393f;
                    color: #fff;
                    border-radius: 6px;
                    border: 1px solid #23272a;
                    alternate-background-color: #2f3136;
                }
                QTableWidget::item:selected {
                    background-color: #5865f2;
                    color: #fff;
                }
            ''')
            vbox = QVBoxLayout()
            vbox.addWidget(self.changed_files_widget)
            self.changed_files_group.setLayout(vbox)
            # Insert after status label
            main_panel = self.centralWidget().widget(1)
            main_layout = main_panel.layout()
            main_layout.insertWidget(3, self.changed_files_group)
        self.changed_files_widget.setRowCount(len(changed_files))
        for row, (icon, file, status) in enumerate(changed_files):
            icon_item = QTableWidgetItem(icon)
            icon_item.setTextAlignment(Qt.AlignCenter)
            self.changed_files_widget.setItem(row, 0, icon_item)
            file_item = QTableWidgetItem(file)
            file_item.setFont(QFont("Arial", 13))
            self.changed_files_widget.setItem(row, 1, file_item)
            status_item = QTableWidgetItem(status)
            status_item.setFont(QFont("Arial", 13))
            self.changed_files_widget.setItem(row, 2, status_item)
        self.changed_files_widget.resizeRowsToContents()
        self.changed_files_group.show()
        self.changed_files_widget.show()

    def filter_repos(self):
        self.refresh_sidebar()
        self.refresh_main_panel()

    def sidebar_select_repo(self, item):
        self.selected_repo = item.data(Qt.UserRole)
        self.refresh_main_panel()

    def get_selected_repo(self):
        if self.repo_list.currentRow() < 0:
            return None
        item = self.repo_list.currentItem()
        if item:
            return item.data(Qt.UserRole)
        return None

    def add_commit(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        msg_box = QMessageBox(self)
        msg_box.setWindowTitle("Commit Message")
        msg_box.setText("Generate commit message automatically?")
        msg_box.setStandardButtons(QMessageBox.Yes | QMessageBox.No | QMessageBox.Cancel)
        choice = msg_box.exec_()
        if choice == QMessageBox.Cancel:
            return
        if choice == QMessageBox.Yes:
            changed_files = subprocess.run(["git", "-C", repo, "status", "--porcelain"], capture_output=True, text=True)
            files = ' '.join([line.split()[-1] for line in changed_files.stdout.strip().splitlines()])
            if not files:
                QMessageBox.warning(self, "Error", "No changes to commit.")
                return
            commit_msg = f"Update files: {files}"
        else:
            commit_msg, ok = QInputDialog.getText(self, "Commit Message", "Enter commit message:")
            if not ok or not commit_msg:
                return
        try:
            subprocess.run(["git", "-C", repo, "add", "."], check=True)
            subprocess.run(["git", "-C", repo, "commit", "-m", commit_msg], check=True)
            QMessageBox.information(self, "Success", "✅ Changes committed successfully.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "❌ Commit failed.")

    def push(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        # Get branches
        branches = subprocess.run(["git", "-C", repo, "branch", "--format=%(refname:short)"], capture_output=True, text=True)
        branch_list = [b for b in branches.stdout.strip().splitlines() if b]
        if not branch_list:
            QMessageBox.warning(self, "Error", "No branches found.")
            return
        branch, ok = QInputDialog.getItem(self, "Select Branch", "Branch to push:", branch_list, editable=False)
        if not ok or not branch:
            return
        try:
            subprocess.run(["git", "-C", repo, "push", "origin", branch], check=True)
            QMessageBox.information(self, "Success", f"✅ Pushed to remote branch '{branch}'.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "❌ Push failed.")

    def pull(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        # Get current branch
        branch = subprocess.run(["git", "-C", repo, "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True, text=True)
        branch_name = branch.stdout.strip() or "main"
        try:
            subprocess.run(["git", "-C", repo, "pull", "origin", branch_name], check=True)
            QMessageBox.information(self, "Success", f"✅ Pulled latest changes for branch '{branch_name}'.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "❌ Pull failed.")

    def show_status(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        result = subprocess.run(["git", "-C", repo, "status"], capture_output=True, text=True)
        QMessageBox.information(self, "Git Status", result.stdout)

    def show_log(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        result = subprocess.run(["git", "-C", repo, "--no-pager", "log", "--oneline", "--graph", "--decorate", "-n", "10"], capture_output=True, text=True)
        QMessageBox.information(self, "Recent Commits", result.stdout)

    def stash(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        try:
            subprocess.run(["git", "-C", repo, "stash"], check=True)
            QMessageBox.information(self, "Success", "✅ Changes stashed successfully.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "❌ Failed to stash changes.")

    def pop_stash(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        try:
            subprocess.run(["git", "-C", repo, "stash", "pop"], check=True)
            QMessageBox.information(self, "Success", "✅ Latest stash applied successfully.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "❌ Failed to pop stash.")

    def advanced_log(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        author, ok1 = QInputDialog.getText(self, "Advanced Log", "Filter by author (leave blank for all):")
        if not ok1:
            return
        branch, ok2 = QInputDialog.getText(self, "Advanced Log", "Filter by branch (leave blank for current):")
        if not ok2:
            return
        log_cmd = ["git", "-C", repo, "--no-pager", "log", "--pretty=format:%C(yellow)%h%Creset %C(cyan)%ad%Creset %C(green)%an%Creset %s", "--date=short", "-n", "20"]
        if author:
            log_cmd.append(f"--author={author}")
        if branch:
            log_cmd.append(branch)
        result = subprocess.run(log_cmd, capture_output=True, text=True)
        QMessageBox.information(self, "Advanced Log", result.stdout)

    def delete_repo(self):
        repo = self.get_selected_repo()
        if not repo:
            return
        name = os.path.basename(repo)
        confirm = QMessageBox.question(self, "Delete Repository", f"Are you sure you want to delete '{name}'? This cannot be undone.", QMessageBox.Yes | QMessageBox.No)
        if confirm != QMessageBox.Yes:
            return
        confirm2, ok = QInputDialog.getText(self, "Confirm Deletion", "Type 'delete' to permanently remove this repository:")
        if not ok or confirm2 != "delete":
            QMessageBox.information(self, "Cancelled", "Deletion cancelled.")
            return
        try:
            import shutil
            shutil.rmtree(repo)
            QMessageBox.information(self, "Success", "✅ Repository deleted successfully.")
            self.repos.remove(repo)
            self.repo_status.pop(repo, None)
            self.refresh_sidebar()
            self.refresh_main_panel()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"❌ Failed to delete repository. {e}")

    def clone_repo(self):
        url, ok1 = QInputDialog.getText(self, "Clone Repository", "Enter the git repository URL:")
        if not ok1 or not url:
            return
        dest, ok2 = QInputDialog.getText(self, "Clone Repository", "Enter the destination directory (leave blank for default):")
        if not ok2:
            return
        try:
            if dest:
                subprocess.run(["git", "clone", url, dest], check=True)
            else:
                subprocess.run(["git", "clone", url], check=True)
            QMessageBox.information(self, "Success", "✅ Repository cloned successfully.")
        except subprocess.CalledProcessError:
            QMessageBox.critical(self, "Error", "❌ Failed to clone repository.")

    def batch_status(self):
        from PyQt5.QtWidgets import QDialog, QTableWidget, QVBoxLayout, QTableWidgetItem, QLabel
        dialog = QDialog(self)
        dialog.setWindowTitle("Batch Status - All Repositories")
        dialog.setStyleSheet(self.styleSheet())
        layout = QVBoxLayout(dialog)
        table = QTableWidget(0, 4)
        table.setHorizontalHeaderLabels(["Status", "Name", "Path", "Message"])
        table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        for repo in self.repos:
            emoji, name, path, status_msg = self.repo_status.get(repo, ("", "", repo, ""))
            # Determine status message
            msg = "Clean"
            try:
                status = subprocess.run(["git", "-C", repo, "status", "--porcelain"], capture_output=True, text=True)
                if status.stdout.strip():
                    msg = "Uncommitted changes"
                branch = subprocess.run(["git", "-C", repo, "status", "-sb"], capture_output=True, text=True)
                if '[ahead ' in branch.stdout:
                    if msg == "Uncommitted changes":
                        msg = "Uncommitted & unpushed"
                    else:
                        msg = "Unpushed commits"
            except Exception:
                msg = "?"
            row = table.rowCount()
            table.insertRow(row)
            table.setItem(row, 0, QTableWidgetItem(emoji))
            table.setItem(row, 1, QTableWidgetItem(name))
            table.setItem(row, 2, QTableWidgetItem(path))
            table.setItem(row, 3, QTableWidgetItem(msg))
        layout.addWidget(QLabel("All repositories and their statuses:"))
        layout.addWidget(table)
        dialog.setLayout(layout)
        dialog.exec_()

    def export_repos(self):
        export_file = os.path.expanduser("~/.gitcompass_export.txt")
        try:
            with open(export_file, "w") as f:
                for repo in self.repos:
                    emoji, name, path, status_msg = self.repo_status.get(repo, ("", "", repo, ""))
                    msg = "Clean"
                    try:
                        status = subprocess.run(["git", "-C", repo, "status", "--porcelain"], capture_output=True, text=True)
                        if status.stdout.strip():
                            msg = "Uncommitted changes"
                        branch = subprocess.run(["git", "-C", repo, "status", "-sb"], capture_output=True, text=True)
                        if '[ahead ' in branch.stdout:
                            if msg == "Uncommitted changes":
                                msg = "Uncommitted & unpushed"
                            else:
                                msg = "Unpushed commits"
                    except Exception:
                        msg = "?"
                    f.write(f"{name}|{repo}|{msg}\n")
            QMessageBox.information(self, "Export", f"Exported to {export_file}")
        except Exception as e:
            QMessageBox.critical(self, "Export", f"Export failed: {e}")

    def import_repos(self):
        import_file = os.path.expanduser("~/.gitcompass_export.txt")
        if not os.path.exists(import_file):
            QMessageBox.warning(self, "Import", f"No export file found at {import_file}")
            return
        from PyQt5.QtWidgets import QDialog, QTableWidget, QVBoxLayout, QTableWidgetItem, QLabel
        dialog = QDialog(self)
        dialog.setWindowTitle("Imported Repository List and Statuses")
        dialog.setStyleSheet(self.styleSheet())
        layout = QVBoxLayout(dialog)
        table = QTableWidget(0, 4)
        table.setHorizontalHeaderLabels(["No.", "Name", "Path", "Status"])
        table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        with open(import_file) as f:
            for n, line in enumerate(f, 1):
                parts = line.strip().split("|")
                if len(parts) == 3:
                    name, path, msg = parts
                    row = table.rowCount()
                    table.insertRow(row)
                    table.setItem(row, 0, QTableWidgetItem(str(n)))
                    table.setItem(row, 1, QTableWidgetItem(name))
                    table.setItem(row, 2, QTableWidgetItem(path))
                    table.setItem(row, 3, QTableWidgetItem(msg))
        layout.addWidget(QLabel("Imported repository list and statuses:"))
        layout.addWidget(table)
        dialog.setLayout(layout)
        dialog.exec_()

    def show_settings(self):
        from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLineEdit, QLabel, QPushButton
        import json
        config_file = os.path.expanduser("~/.gitcompassrc.json")
        default_branch = ""
        if os.path.exists(config_file):
            try:
                with open(config_file) as f:
                    data = json.load(f)
                    default_branch = data.get("default_branch", "")
            except Exception:
                pass
        dialog = QDialog(self)
        dialog.setWindowTitle("Settings")
        dialog.setStyleSheet(self.styleSheet())
        layout = QVBoxLayout(dialog)
        layout.addWidget(QLabel("Set default branch (used for push/pull):"))
        branch_edit = QLineEdit(default_branch)
        layout.addWidget(branch_edit)
        save_btn = QPushButton("Save")
        layout.addWidget(save_btn)
        def save():
            with open(config_file, "w") as f:
                json.dump({"default_branch": branch_edit.text()}, f)
            dialog.accept()
        save_btn.clicked.connect(save)
        dialog.setLayout(layout)
        dialog.exec_()

    def show_help(self):
        from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel
        dialog = QDialog(self)
        dialog.setWindowTitle("Help / About GitCompass")
        dialog.setStyleSheet(self.styleSheet())
        layout = QVBoxLayout(dialog)
        layout.addWidget(QLabel("<b>GitCompass v1.0.0</b> - Your Git Repository Navigator"))
        layout.addWidget(QLabel("<b>Features:</b>"))
        layout.addWidget(QLabel("- Scan and manage all your Git repositories from one place."))
        layout.addWidget(QLabel("- See status indicators for uncommitted and unpushed changes."))
        layout.addWidget(QLabel("- Add/commit, push, pull, view status, and see recent commit log."))
        layout.addWidget(QLabel("- Stash, pop, advanced log, delete, clone, batch status, export/import."))
        layout.addWidget(QLabel("- User-friendly, Discord-themed interface."))
        layout.addWidget(QLabel("<br>Status Legend: 🟢 Clean  🟡 Uncommitted changes  🟠 Unpushed commits"))
        layout.addWidget(QLabel("<br>Created by Goal651. Enjoy hacking!"))
        dialog.setLayout(layout)
        dialog.exec_()

    def closeEvent(self, event):
        # Wait for all threads to finish before closing
        for thread in self.threads:
            if thread.isRunning():
                thread.quit()
                thread.wait()
        event.accept()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = GitManager()
    window.show()
    sys.exit(app.exec_())