"""用户 Pydantic 校验模型"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, field_validator


# ── 请求体 ──

class UserCreate(BaseModel):
    username: str  # 2-50 字符
    email: EmailStr
    password: str  # 6-50 字符
    nickname: str = ""

    @field_validator("username")
    @classmethod
    def username_valid(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2 or len(v) > 50:
            raise ValueError("用户名需要 2-50 个字符")
        return v

    @field_validator("password")
    @classmethod
    def password_valid(cls, v: str) -> str:
        if len(v) < 6 or len(v) > 50:
            raise ValueError("密码需要 6-50 个字符")
        return v


class UserLogin(BaseModel):
    username: str
    password: str


class UserUpdate(BaseModel):
    nickname: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None


# ── 响应体 ──

class UserOut(BaseModel):
    id: str
    username: str
    email: str
    nickname: str
    role: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class MessageOut(BaseModel):
    message: str
