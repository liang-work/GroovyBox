import flet as ft
import os
from typing import Optional
from logic.localize import tr


class UniversalImage(ft.Container):
    def __init__(
        self,
        uri: Optional[str] = None,
        width: Optional[float] = None,
        height: Optional[float] = None,
        border_radius: Optional[float] = None,
        fit: ft.BoxFit = ft.BoxFit.COVER,
        fallback_icon: str = ft.Icons.IMAGE,
        fallback_icon_size: float = 48,
    ):
        self._uri = uri
        self._fit = fit
        self._fallback_icon = fallback_icon
        self._fallback_icon_size = fallback_icon_size
        self._border_radius_val = border_radius

        content = self._build_content()

        super().__init__(
            content=content,
            width=width,
            height=height,
            border_radius=border_radius,
            clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
            bgcolor=ft.Colors.with_opacity(0.1, ft.Colors.GREY),
        )

    def _is_network(self, uri: str) -> bool:
        return uri.startswith("http://") or uri.startswith("https://")

    def _build_content(self):
        if not self._uri or not os.path.isfile(self._uri):
            return ft.Icon(
                icon=self._fallback_icon,
                size=self._fallback_icon_size,
                color=ft.Colors.WHITE54,
            )

        if self._is_network(self._uri):
            return ft.Image(
                src=self._uri,
                fit=self._fit,
                error_content=ft.Icon(
                    icon=self._fallback_icon,
                    size=self._fallback_icon_size,
                    color=ft.Colors.WHITE54,
                ),
            )
        else:
            return ft.Image(
                src=self._uri,
                fit=self._fit,
                error_content=ft.Icon(
                    icon=self._fallback_icon,
                    size=self._fallback_icon_size,
                    color=ft.Colors.WHITE54,
                ),
            )
