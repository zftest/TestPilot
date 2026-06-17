"""用户管理 API — 列表 / 更新 / 禁用"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import User
from app.schemas.user import UserOut, UserUpdate, MessageOut
from app.api.deps import get_current_user, require_admin

router = APIRouter(prefix="/users", tags=["用户管理"])


@router.get("", response_model=list[UserOut])
def list_users(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    keyword: str = Query("", description="用户名/邮箱搜索"),
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """获取用户列表（分页 + 搜索）"""
    q = db.query(User)
    if keyword:
        q = q.filter(
            (User.username.like(f"%{keyword}%"))
            | (User.email.like(f"%{keyword}%"))
        )
    total = q.count()
    users = q.order_by(User.created_at.desc()).offset((page - 1) * size).limit(size).all()
    return [UserOut.model_validate(u) for u in users]
    # Note: total 可通过 X-Total-Count header 返回，此处简化


@router.get("/{user_id}", response_model=UserOut)
def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """获取单个用户"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return UserOut.model_validate(user)


@router.put("/{user_id}", response_model=UserOut)
def update_user(
    user_id: str,
    body: UserUpdate,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """更新用户信息（仅管理员）"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    update_data = body.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(user, k, v)
    db.commit()
    db.refresh(user)
    return UserOut.model_validate(user)
