import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "check-in-routes",

  initialize(container) {
    const router = container.lookup('router:main');
    router.map(function() {
      this.route("check-in", { path: "/check-in" });
    });

    withPluginApi("0.8.31", (api) => {
      // Add navigation item to hamburger menu
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
    });
  }
};
