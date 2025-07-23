import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "check-in-navigation",

  initialize() {
    withPluginApi("0.8.31", (api) => {
      // 在汉堡菜单中添加签到链接
      api.decorateWidget("hamburger-menu:generalLinks", (helper) => {
        if (helper.currentUser) {
          return helper.h("li", [
            helper.h("a.widget-link", {
              href: "/check-in"
            }, [
              helper.h("span.d-icon.d-icon-calendar-plus"),
              " 每日签到"
            ])
          ]);
        }
      });
    });
  }
};
