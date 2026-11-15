// Claude OS: set the Application Launcher icon to the Claude OS logo.
// Plasma runs each update script once per user.
const allPanels = panels();

for (let i = 0; i < allPanels.length; ++i) {
    const widgets = allPanels[i].widgets();

    for (let j = 0; j < widgets.length; ++j) {
        const widget = widgets[j];

        if (widget.type === "org.kde.plasma.kickoff") {
            widget.currentConfigGroup = ["General"];
            widget.writeConfig("icon", "claudeos-logo");
            widget.reloadConfig();
        }
    }
}
