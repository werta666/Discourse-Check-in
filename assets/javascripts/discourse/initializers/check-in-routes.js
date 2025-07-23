import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "check-in-routes",
  
  initialize() {
    withPluginApi("0.8.31", (api) => {
      // Add check-in route
      api.addRoute("check-in", {
        path: "/check-in",
        resetNamespace: true
      });

      // Add navigation item
      api.decorateWidget("hamburger-menu:generalLinks", (helper) => {
        if (helper.currentUser) {
          return helper.h("li", [
            helper.h("a.widget-link", {
              href: helper.url("/check-in"),
              attributes: { "data-auto-route": true }
            }, [
              helper.h("span.d-icon.d-icon-calendar-plus"),
              " ",
              I18n.t("check_in.nav_title")
            ])
          ]);
        }
      });

      // Add to user menu if available
      api.addUserMenuGlyph((widget) => {
        if (widget.currentUser) {
          return {
            label: I18n.t("check_in.nav_title"),
            className: "check-in-link",
            icon: "calendar-plus",
            href: "/check-in"
          };
        }
      });
    });
  }
};
